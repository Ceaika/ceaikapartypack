untyped
global function Cl_Echo_Init
global function Echo_ScreechFX
global function Echo_HiderVocalFX
global function Echo_DecoyMotion
global function Echo_DecoyFX
global function Echo_GruntNotice
global function Echo_AdminNotice
global function Echo_AdminNoticeClear
struct
{
    string gruntNotice = ""
    float adminNoticeUntil = 0.0
    float gruntNoticeUntil = 0.0
    int lastGruntNotice = -1
    int hiderCorrection = -1
    entity hiderLight = null
    array<int> hiderMist
    float nextMistUpdate = 0.0
    float nextHeartbeat = 0.0
    float heartbeatStop = 0.0
    int correction = -1
    int waitingCorrection = -1
    int activeCorrection = -1
    array<int> fadeCorrections
    int vision = 0
    float savedHidingVolume = -1.0
    table<entity,table> noise
} file

void function Cl_Echo_Init()
{
    PrecacheModel(ECHO_PROWLER)
    PrecacheParticleSystem($"echo_hider_mist")
    PrecacheWeapon("melee_echo_claw")
    ClGameState_RegisterGameStateAsset($"ui/gamestate_info_lts.rpak")
    AddCallback_IsValidMeleeExecutionTarget(Echo_CanExecute)
    file.hiderCorrection=ColorCorrection_Register("materials/correction/echo_hider.raw")
    file.correction=ColorCorrection_Register("materials/correction/echo_lidar.raw")
    file.waitingCorrection=ColorCorrection_Register("materials/correction/echo_wait.raw")
    file.fadeCorrections.append(file.waitingCorrection)
    for(int i=1;i<8;i++)
        file.fadeCorrections.append(ColorCorrection_Register(format("materials/correction/echo_fade_%02d.raw",i)))
    file.fadeCorrections.append(file.correction)
    EchoScan_Init()
    Echo_HeartClientInit()
    thread Echo_ClientLoop()
    thread Echo_Bodies()
    thread Echo_TeammateOutlines()
}
void function Echo_ClearRipples()
{
    file.noise.clear()
    EchoScan_Clear()
}
void function Echo_Vision(int mode)
{
    if(mode==file.vision) return
    if(mode==1 && file.savedHidingVolume<0.0)
    {
        file.savedHidingVolume=GetSoundVolume()
        SetSoundVolume(0.0)
    }
    else if(mode!=1 && file.savedHidingVolume>=0.0)
    {
        SetSoundVolume(file.savedHidingVolume)
        file.savedHidingVolume=-1.0
    }
    if(file.activeCorrection>=0)
    {
        ColorCorrection_SetWeight(file.activeCorrection,0.0)
        ColorCorrection_SetExclusive(file.activeCorrection,false)
        file.activeCorrection=-1
    }
    Echo_ClearRipples()
    Echo_ClearHiderMist()
    file.gruntNoticeUntil=0.0
    if(IsValid(file.hiderLight)) file.hiderLight.Destroy()
    file.hiderLight=null
    entity viewer=GetLocalClientPlayer()
    if(IsValid(viewer)) StopSoundOnEntity(viewer,"Wilds_Scr_HelmetHUDText_Finish")
    file.nextHeartbeat=0.0
    file.heartbeatStop=0.0
    EchoScan_SetBlind(mode==1 || mode==2)
    file.vision=mode
    if(mode==0) Minimap_EnableDraw()
    else
    {
        int cc=mode==3 ? file.hiderCorrection : file.waitingCorrection
        ColorCorrection_SetExclusive(cc,true)
        ColorCorrection_SetWeight(cc,1.0)
        file.activeCorrection=cc
        Minimap_DisableDraw()
    }
}
// only ONE exclusive color lookup at a time, blending two leaks the normal looking map.
// found that out when the whole map just showed up normal mid round lmao
void function Echo_UpdateFilter()
{
    if(file.vision!=2 || file.activeCorrection==file.correction) return
    if(file.activeCorrection>=0)
    {
        ColorCorrection_SetWeight(file.activeCorrection,0.0)
        ColorCorrection_SetExclusive(file.activeCorrection,false)
    }
    ColorCorrection_SetExclusive(file.correction,true)
    ColorCorrection_SetWeight(file.correction,1.0)
    file.activeCorrection=file.correction
}
void function Echo_ScreechFX(float x,float y,float z)
{
    EchoScan_Screech(<x,y,z>,GetCurrentPlaylistVarFloat("echo_screech_radius",960.0),GetCurrentPlaylistVarFloat("echo_screech_seconds",3.0))
}
void function Echo_HiderVocalFX(int handle,float x,float y,float z)
{
    EchoScan_NoiseAt(<x,y,z>,GetCurrentPlaylistVarFloat("echo_noise_radius_max",240.0),0.65,GetEntityFromEncodedEHandle(handle),0.85)
}
void function Echo_DecoyFX(float x,float y,float z)
{
    EchoScan_NoiseAt(<x,y,z>,240.0,0.5,null,0.85,true)
}
void function Echo_Noise(entity p,float intensity,string kind="other",bool silhouette=true)
{
    intensity=clamp(intensity,0.0,1.0)
    float radius=GraphCapped(intensity,0.0,1.0,GetCurrentPlaylistVarFloat("echo_noise_radius_min",80.0),GetCurrentPlaylistVarFloat("echo_noise_radius_max",240.0))
    float seconds=GraphCapped(intensity,0.0,1.0,GetCurrentPlaylistVarFloat("echo_noise_seconds_min",0.25),GetCurrentPlaylistVarFloat("echo_noise_seconds_max",0.8))
    if(p==GetLocalClientPlayer()) radius*=GetCurrentPlaylistVarFloat("echo_own_noise_scale",0.45)
    bool trail=kind=="slide" || kind=="shoved slide" || (kind=="step" && Length2D(p.GetVelocity())>=GetCurrentPlaylistVarFloat("echo_sprint_speed",220.0))
    if(kind=="jump") EchoScan_AudibleJump(p)
    bool continuous=kind=="jump" || kind=="step" || kind=="slide" || kind=="shoved slide" || kind=="wallrun" || kind=="zipline"
    EchoScan_Noise(p,radius,trail ? min(seconds,0.2) : seconds,GraphCapped(intensity,0.0,1.0,0.25,1.0),trail,silhouette,continuous)
    if(GetCurrentPlaylistVarInt("echo_noise_debug",0)>0) print("[ECHO-NOISE] "+kind+" intensity="+intensity+" silhouette="+silhouette+" source="+p.GetOrigin())
}
// hiders only have melee + noise decoys. DONT read another player's ammo/reload here,
// querying a remote weapon kills this thread. took me a day to figure out why hush randomly broke
void function Echo_Listen(entity listener)
{
    array<entity> heard
    float range=GetCurrentPlaylistVarFloat("echo_noise_range",3072.0)
    foreach(entity p in GetPlayerArray())
    {
        if(!IsValid(p) || !IsAlive(p) || !p.GetPlayerNetBool("echoActive") || p.GetPlayerNetBool("echoHunter") || DistanceSqr(listener.GetOrigin(),p.GetOrigin())>range*range) continue
        heard.append(p)
        vector velocity=p.GetVelocity()
        float speed=Length2D(velocity)
        bool ground=p.IsOnGround()
        bool climbing=p.IsTraversing()
        bool meleeActive=p.PlayerMelee_IsAttackActive()
        if(!(p in file.noise))
        {
            file.noise[p] <- {ground=ground,fallVelocity=velocity.z,melee=meleeActive,climbing=climbing,nextStep=Time(),nextZipline=0.0}
            continue
        }
        table old=file.noise[p]
        bool shoved=Time()<p.GetPlayerNetTime("echoShovedUntil")
        bool sliding=p.IsSliding() || shoved
        bool wall=p.IsWallRunning()
        bool quiet=p.GetPlayerNetBool("echoQuiet") && !shoved
        // ziplines are always noisy even crouched or stopped on the rope
        bool ziplining=p.IsZiplining()
        if(ziplining && Time()>=old.nextZipline)
        {
            Echo_Noise(p,GetCurrentPlaylistVarFloat("echo_noise_run",0.5),"zipline")
            old.nextZipline=Time()+0.1
        }
        if(!ziplining) old.nextZipline=0.0
        bool mantle=climbing || expect bool(old.climbing)
        bool landed=!expect bool(old.ground) && ground
        if(!ziplining && !mantle && !landed && speed>GetCurrentPlaylistVarFloat("echo_walk_speed",35.0) && !quiet && (ground || wall) && Time()>=old.nextStep)
        {
            float intensity=shoved ? GetCurrentPlaylistVarFloat("echo_noise_shove",0.85) : (sliding || wall || speed>=GetCurrentPlaylistVarFloat("echo_sprint_speed",220.0)) ? GetCurrentPlaylistVarFloat("echo_noise_run",0.5) : GetCurrentPlaylistVarFloat("echo_noise_walk",0.25)
            Echo_Noise(p,intensity,shoved ? "shoved slide" : wall ? "wallrun" : (sliding ? "slide" : "step"))
            old.nextStep=Time()+(shoved ? 0.2 : max(0.05,GetCurrentPlaylistVarFloat("echo_step_interval",0.35)))
        }
        if(!ziplining && !quiet && !mantle && ((old.ground && !ground && velocity.z>GetCurrentPlaylistVarFloat("echo_jump_speed",80.0)) || (!ground && !climbing && velocity.z>100.0 && velocity.z-old.fallVelocity>100.0)))
            Echo_Noise(p,GetCurrentPlaylistVarFloat("echo_noise_jump",0.6),"jump")
        if(!ziplining && climbing && !old.climbing) Echo_Noise(p,GetCurrentPlaylistVarFloat("echo_noise_soft",0.15),"climb",false)
        if(!quiet && landed && old.fallVelocity<0)
        {
            // soft landings and mantle exits keep the sound + a faint patch but dont move the silhouette
            float fallSpeed=-expect float(old.fallVelocity)
            if(mantle || fallSpeed<GetCurrentPlaylistVarFloat("echo_land_speed",176.78))
                Echo_Noise(p,GetCurrentPlaylistVarFloat("echo_noise_soft",0.15),"soft land",false)
            else
                Echo_Noise(p,GraphCapped(fallSpeed,GetCurrentPlaylistVarFloat("echo_land_speed",176.78),GetCurrentPlaylistVarFloat("echo_land_hard_speed",800.0),GetCurrentPlaylistVarFloat("echo_noise_land",0.3),1.0),"land")
            old.nextStep=Time()+max(0.05,GetCurrentPlaylistVarFloat("echo_step_interval",0.35))
        }
        if(meleeActive && !old.melee) Echo_Noise(p,GetCurrentPlaylistVarFloat("echo_noise_melee",0.2),"melee")
        old.climbing=climbing; old.ground=ground; old.fallVelocity=velocity.z; old.melee=meleeActive
    }
    array<entity> stale
    foreach(entity p,table state in file.noise) if(!heard.contains(p)) stale.append(p)
    foreach(entity p in stale) delete file.noise[p]
}
void function Echo_AdminNotice()
{
    file.adminNoticeUntil = Time()+5.0
}
void function Echo_AdminNoticeClear() { file.adminNoticeUntil = 0.0 }

void function Echo_GruntNotice()
{
    entity p=GetLocalClientPlayer()
    if(!IsValid(p) || !IsAlive(p) || !p.GetPlayerNetBool("echoActive") || p.GetPlayerNetBool("echoHunter")) return
    array<string> messages=["You stubbed your toe", "There's a pebble in your shoe", "You strained your back", "You decided to grunt for some reason",
        "You got startled by a bug", "You held in a sneeze", "You tested if the Prowler can hear you"]
    int choice=file.lastGruntNotice<0 ? RandomIntRange(0,messages.len()) : (file.lastGruntNotice+RandomIntRange(1,messages.len()))%messages.len()
    file.lastGruntNotice=choice
    file.gruntNotice=messages[choice]
    file.gruntNoticeUntil=Time()+5.0
    if(GetCurrentPlaylistVarInt("echo_noise_debug",0)>0) print("[ECHO-NOTICE] "+file.gruntNotice)
}
var function Echo_Text(float size,vector color,vector position,bool centered=false)
{
    var rui=CreateFullscreenRui(centered ? $"ui/cockpit_console_text_center.rpak" : $"ui/cockpit_console_text_top_left.rpak",850)
    RuiSetInt(rui,"maxLines",4)
    RuiSetInt(rui,"lineNum",0)
    RuiSetFloat(rui,"msgFontSize",size)
    RuiSetFloat(rui,"msgAlpha",0.0)
    RuiSetFloat(rui,"thicken",0.0)
    RuiSetFloat3(rui,"msgColor",color)
    RuiSetFloat2(rui,"msgPos",position)
    return rui
}
void function Echo_ClientLoop()
{
    // hiders get one stock objective line: SURVIVE. nobody else gets hud
    var objective=CreatePermanentCockpitRui($"ui/fw_objective_text.rpak",0)
    RuiSetString(objective,"objective","")
    var notice=Echo_Text(28.0,<1.0,0.85,0.60>,<0,0.28,0>,true)
    OnThreadEnd(function() : (objective,notice) {
        Echo_Vision(0)
        Echo_ClearRipples()
        RuiDestroyIfAlive(objective)
        RuiDestroy(notice)
    })
    while(true)
    {
        entity p=GetLocalClientPlayer()
        if(!IsValid(p))
        {
            Echo_Vision(0)
            RuiSetFloat(notice,"msgAlpha",0.0)
            RuiSetString(objective,"objective","")
            wait 0.1
            continue
        }
        int phase=GetGlobalNetInt("echoPhase")
        bool active=IsValid(p) && IsAlive(p) && p.GetPlayerNetBool("echoActive")
        bool hunter=active && !p.IsObserver() && GetLocalViewPlayer()==p && p.GetPlayerNetBool("echoHunter")
        bool playing=GetGameState()==eGameState.Playing
        bool hider=active && !hunter && !p.IsObserver() && GetLocalViewPlayer()==p
        Echo_Vision(playing && (phase==1 || phase==2) ? (hunter ? phase : hider ? 3 : 0) : 0)
        Echo_HiderAtmosphere(p)
        Echo_Heartbeat(p,playing && hider && phase==2)
        string notification=""
        float noticeAlpha=0.0
        if(hunter && phase==2)
        {
            Echo_Listen(p)
            if(Echo_NearestOpponent(p,false)<GetCurrentPlaylistVarFloat("echo_odor_range",220.0))
            {
                notification="You smell a strange odor."
                noticeAlpha=1.0
            }
        }
        else if(hider && phase==2 && Time()<file.gruntNoticeUntil)
        {
            notification=file.gruntNotice
            float age=5.0-(file.gruntNoticeUntil-Time())
            noticeAlpha=min(clamp(age/0.15,0.0,1.0),clamp((file.gruntNoticeUntil-Time())/0.65,0.0,1.0))
        }
        if (active && Time()<file.adminNoticeUntil)
        {
            notification = "you feel like the admin is messing with you"
            noticeAlpha = clamp((file.adminNoticeUntil-Time())/0.65,0.0,1.0)
        }
        Echo_UpdateFilter()
        RuiSetString(objective,"objective",playing && hider && (phase==1 || phase==2) ? "SURVIVE" : "")
        RuiSetString(notice,"msgText",notification)
        RuiSetFloat(notice,"msgAlpha",playing ? noticeAlpha : 0.0)
        wait max(0.02,GetCurrentPlaylistVarFloat("echo_noise_tick",0.05))
    }
}




// same trick as prop hunt: visuals on the interpolated player origin, no trailing body
void function Echo_Bodies()
{
    table<entity,table> bodies
    OnThreadEnd(function() : (bodies) {
        foreach(entity p,table body in bodies) if(IsValid(body.model)) body.model.Destroy()
    })
    while(true)
    {
        array<entity> active
        foreach(entity p in GetPlayerArray())
        {
            if(!IsValid(p) || !IsAlive(p) || !p.GetPlayerNetBool("echoActive") || !p.GetPlayerNetBool("echoHunter") || p==GetLocalViewPlayer()) continue
            active.append(p)
            if(!(p in bodies)) bodies[p] <- Echo_NewBody(p.GetOrigin(),p.EyeAngles().y)
            Echo_UpdateBody(bodies[p],p.GetOrigin(),p.EyeAngles().y,p.GetVelocity(),p.IsOnGround(),p.IsTraversing(),p.IsCrouched(),p.PlayerMelee_IsAttackActive(),p.GetPlayerNetTime("echoLastScreech"))
            entity viewer=GetLocalViewPlayer()
            bool reveal=GetGlobalNetInt("echoPhase")==1 && IsValid(viewer) && IsAlive(viewer) && viewer.GetPlayerNetBool("echoActive") && !viewer.GetPlayerNetBool("echoHunter")
            entity model=expect entity(bodies[p].model)
            Echo_ProwlerSpawnOutline(model,reveal)
        }
        array<entity> stale
        foreach(entity p,table body in bodies) if(!active.contains(p)) stale.append(p)
        foreach(entity p in stale)
        {
            if(IsValid(bodies[p].model)) bodies[p].model.Destroy()
            delete bodies[p]
        }
        WaitFrame()
    }
}

// smooth the visual body only, camera and movement stay instant
float function Echo_TurnYaw(float current,float target,float seconds)
{
    float delta=target-current
    while(delta>180.0) delta-=360.0
    while(delta< -180.0) delta+=360.0
    float blend=clamp(12.0*seconds,0.0,1.0)
    return current+clamp(delta*blend,-540.0*seconds,540.0*seconds)
}
table function Echo_NewBody(vector origin,float yaw)
{
    return {model=CreateClientSidePropDynamic(origin,<0,yaw,0>,ECHO_PROWLER),sequence="",rate=1.0,until=0.0,animEnd=0.0,melee=false,yaw=yaw,lastTurn=Time(),climbing=false,mantle="pr_traverse_jump_up_38",mantleRate=1.0,lastSpeed=0.0}
}
void function Echo_UpdateBody(table body,vector origin,float yaw,vector velocity,bool grounded,bool climbing,bool crouched,bool meleeActive,float lastScreech)
{
    float speed=Length2D(velocity)
    if(climbing && !body.climbing)
    {
        // latch on entry so wobbly traversal speed cant restart the pose
        float approach=max(speed,expect float(body.lastSpeed))
        body.mantle=approach>240.0 ? "pr_traverse_across_128" : (approach>100.0 ? "pr_traverse_jump_up_38" : "pr_traverse_jump_up_64")
        body.mantleRate=approach>240.0 ? 1.4 : (approach>100.0 ? 1.0 : 0.8)
    }
    string sequence=Echo_BodySequence(speed,grounded,climbing,crouched,expect string(body.mantle))
    float rate=climbing ? expect float(body.mantleRate) : (grounded && crouched && speed>5.0 ? 0.35 : 1.0)
    if(meleeActive && !body.melee) body.until=Time()+0.65
    if(Time()<body.until) { sequence="pr_claw_attack"; rate=1.0; }
    bool oneShot=climbing || !grounded || sequence=="pr_claw_attack"
    if(sequence!=body.sequence || (!oneShot && Time()>=body.animEnd))
    {
        body.model.Anim_Play(sequence)
        body.model.SetPlaybackRate(rate)
        body.sequence=sequence
        body.rate=rate
        body.animEnd=Time()+body.model.GetSequenceDuration(sequence)/rate
    }
    else if(rate!=body.rate)
    {
        body.model.SetPlaybackRate(rate)
        body.rate=rate
    }
    if(oneShot && Time()>=body.animEnd) { body.model.SetCycle(0.999); body.model.SetPlaybackRate(0.0); }
    float turnDelta=clamp(Time()-expect float(body.lastTurn),0.0,0.1)
    body.yaw=Echo_TurnYaw(expect float(body.yaw),yaw,turnDelta)
    body.lastTurn=Time()
    body.model.SetAngles(<0,expect float(body.yaw),0>)
    body.model.SetOrigin(origin)
    float plateDuration=max(0.1,body.model.GetSequenceDuration("pr_additive_plate_pulse"))
    float age=Time()-lastScreech
    body.model.SetPoseParameter("hush_screech_cycle",lastScreech>0.0 && age>=0.0 && age<plateDuration ? age/plateDuration : 0.0)
    body.melee=meleeActive
    body.climbing=climbing
    body.lastSpeed=speed
}
string function Echo_BodySequence(float speed,bool grounded,bool climbing,bool crouched,string mantle)
{
    if(climbing) return mantle
    if(!grounded) return "pr_leap_up_128"
    if(crouched && speed>5.0) return "pr_trot_forward"
    if(speed>240.0) return "pr_combat_run_forward"
    if(speed>120.0) return "pr_trot_forward"
    if(speed>35.0) return "pr_walk_forward"
    return "pr_idle_stand"
}

float function Echo_NearestOpponent(entity viewer,bool hunters)
{
    float nearest=99999.0
    foreach(entity other in GetPlayerArray())
        if(IsValid(other) && other!=viewer && IsAlive(other) && other.GetPlayerNetBool("echoActive") && other.GetPlayerNetBool("echoHunter")==hunters)
            nearest=min(nearest,Distance(viewer.GetOrigin(),other.GetOrigin()))
    return nearest
}
void function Echo_HiderAtmosphere(entity p)
{
    if(file.vision!=3) return
    if(!IsValid(file.hiderLight)) file.hiderLight=CreateClientSideDynamicLight(p.EyePosition(),<0,0,0>,<0.0625,0.03125,0.015625>,8192.0+Time()*8.0)
    file.hiderLight.SetOrigin(p.EyePosition())
    file.hiderLight.SetLightRadius(8192.0+Time()*8.0)
    Echo_UpdateHiderMist(p)
}
void function Echo_Heartbeat(entity p,bool active)
{
    string sound="Wilds_Scr_HelmetHUDText_Finish"
    if(file.heartbeatStop>0.0 && (Time()>=file.heartbeatStop || !active))
    {
        StopSoundOnEntity(p,sound)
        file.heartbeatStop=0.0
    }
    if(!active) { file.nextHeartbeat=0.0; return; }
    float distance=Echo_NearestOpponent(p,true)
    float range=GetCurrentPlaylistVarFloat("echo_heartbeat_range",1400.0)
    if(distance>range) { file.nextHeartbeat=0.0; return; }
    float bpm=Echo_HeartbeatBPM(distance,range)
    if(file.nextHeartbeat>0.0) file.nextHeartbeat=min(file.nextHeartbeat,Time()+60.0/bpm)
    if(Time()<file.nextHeartbeat) return
    EmitSoundOnEntity(p,sound)
    file.heartbeatStop=Time()+0.26
    file.nextHeartbeat=Time()+60.0/bpm
    if(GetCurrentPlaylistVarInt("echo_noise_debug",0)>0) print("[ECHO-HEART] distance="+distance+" bpm="+bpm+" next="+file.nextHeartbeat)
}

// client only sprite mist, old particles drift while the emitter follows the hider
void function Echo_ClearHiderMist()
{
    foreach(int fx in file.hiderMist)
        if(EffectDoesExist(fx)) EffectStop(fx,true,false)
    file.hiderMist.clear()
    file.nextMistUpdate=0.0
}
void function Echo_UpdateHiderMist(entity p)
{
    if(Time()<file.nextMistUpdate) return
    file.nextMistUpdate=Time()+0.25
    int index=GetParticleSystemIndex($"echo_hider_mist")
    for(int n=0;n<9;n++)
    {
        vector pos=p.GetOrigin()+<float(n%3-1)*320.0,float(n/3-1)*320.0,0>
        TraceResults ground=TraceLine(pos+<0,0,160>,pos-<0,0,256>,p,TRACE_MASK_PLAYERSOLID,TRACE_COLLISION_GROUP_NONE)
        if(ground.fraction>0.0 && ground.fraction<1.0) pos=ground.endPos
        pos+=<0,0,-30>
        if(n>=file.hiderMist.len())
            file.hiderMist.append(StartParticleEffectInWorldWithHandle(index,pos,<0,0,0>))
        else if(!EffectDoesExist(file.hiderMist[n]))
            file.hiderMist[n]=StartParticleEffectInWorldWithHandle(index,pos,<0,0,0>)
        else EffectSetControlPointVector(file.hiderMist[n],0,pos)
    }
}

// native outlines on the actual teammate, the server owns the shader context
float function Echo_TeammateAlpha(float distance)
{
    float nearRange=max(0.0,GetCurrentPlaylistVarFloat("echo_teammate_full_range",240.0))
    float farRange=max(nearRange+1.0,GetCurrentPlaylistVarFloat("echo_teammate_hide_range",480.0))
    float alpha=GraphCapped(distance,nearRange,farRange,1.0,0.0)
    return alpha*alpha*(3.0-2.0*alpha)
}
void function Echo_ApplyFriendlyOutline(entity teammate,bool initialize=false)
{
    entity viewer=GetLocalClientPlayer()
    float alpha=Echo_TeammateAlpha(Distance(viewer.GetOrigin(),teammate.GetOrigin()))
    teammate.Highlight_SetCurrentContext(1) // native HIGHLIGHT_CONTEXT_FRIENDLY
    teammate.Highlight_ResetFlags()
    teammate.Highlight_SetFlag(HIGHLIGHT_FLAG_REQUIRE_SAME_TEAM,true)
    teammate.Highlight_SetVisibilityType(HIGHLIGHT_VIS_ALWAYS)
    teammate.Highlight_SetNearFadeDist(0.0)
    teammate.Highlight_SetFarFadeDist(100000.0)
    teammate.Highlight_SetFadeInTime(0.0)
    teammate.Highlight_SetFadeOutTime(0.0)
    teammate.Highlight_SetLifeTime(Time()+1.0)
    if(initialize) teammate.Highlight_StartOn()
    teammate.Highlight_HideInside(0.0)
    if(alpha>=0.999) { teammate.Highlight_ShowOutline(0.0); return; }
    if(alpha<=0.001) { teammate.Highlight_HideOutline(0.0); return; }
    // Show/Hide take a fade time not an opacity so we fake it with 50ms steps.
    // this is so dumb but its the only way i got it smooth
    float current=teammate.Highlight_GetCurrentOutlineOpacity()
    float delta=alpha-current
    if(fabs(delta)<0.002) teammate.Highlight_ShowOutline(1000000.0)
    else if(delta>0.0) teammate.Highlight_ShowOutline(max(0.001,0.05*(1.0-current)/delta))
    else teammate.Highlight_HideOutline(max(0.001,0.05*current/(-delta)))
}
void function Echo_HideFriendlyOutline(entity teammate)
{
    if(!IsValid(teammate) || teammate.Highlight_GetCurrentContext()!=1) return
    teammate.Highlight_HideOutline(0.0)
    teammate.Highlight_HideInside(0.0)
}
void function Echo_TeammateOutlines()
{
    array<entity> outlined
    OnThreadEnd(function() : (outlined) {
        foreach(entity teammate in outlined) Echo_HideFriendlyOutline(teammate)
    })
    while(true)
    {
        entity viewer=GetLocalClientPlayer()
        bool enabled=IsValid(viewer) && IsAlive(viewer) && !viewer.IsObserver() && GetLocalViewPlayer()==viewer
        if(enabled) enabled=GetGameState()==eGameState.Playing && viewer.GetPlayerNetBool("echoActive") && !viewer.GetPlayerNetBool("echoHunter")
        if(enabled) enabled=GetGlobalNetInt("echoPhase")==1 || GetGlobalNetInt("echoPhase")==2
        array<entity> keep
        if(enabled) foreach(entity teammate in GetPlayerArray())
        {
            if(!IsValid(teammate) || teammate==viewer || !IsAlive(teammate) || teammate.IsObserver() || teammate.GetTeam()!=viewer.GetTeam() || !teammate.GetPlayerNetBool("echoActive") || teammate.GetPlayerNetBool("echoHunter")) continue
            keep.append(teammate)
            Echo_ApplyFriendlyOutline(teammate,!outlined.contains(teammate))
        }
        foreach(entity teammate in outlined) if(!keep.contains(teammate)) Echo_HideFriendlyOutline(teammate)
        outlined.clear()
        outlined.extend(keep)
        wait 0.05
    }
}
float function Echo_HeartbeatBPM(float distance,float range)
{
    float base=GraphCapped(distance,100.0,range,155.0,60.0)
    float closeRange=max(65.0,GetCurrentPlaylistVarFloat("echo_heartbeat_panic_range",160.0))
    float panic=GetCurrentPlaylistVarFloat("echo_heartbeat_panic_bpm",210.0)
    float blend=GraphCapped(distance,64.0,closeRange,1.0,0.0)
    return base+(clamp(panic,155.0,220.0)-base)*blend
}

void function Echo_DecoyMotion(int id,float x,float y,float z,float yaw,int pose)
{
    EchoScan_DecoyMotion(id,<x,y,z>,yaw,pose)
}


void function Echo_ProwlerSpawnOutline(entity model,bool reveal)
{
            if(reveal)
            {
                model.Highlight_SetInheritHighlight(false)
                model.Highlight_SetFunctions(1,0,true,101,5.0,0,true)
                model.Highlight_SetParam(1,0,<1.4,0.025,0.015>)
                model.Highlight_SetCurrentContext(1)
                model.Highlight_SetVisibilityType(HIGHLIGHT_VIS_ALWAYS)
                model.Highlight_SetNearFadeDist(0.0)
                model.Highlight_SetFarFadeDist(100000.0)
                model.Highlight_SetLifeTime(Time()+1.0)
                model.Highlight_StartOn()
                model.Highlight_HideInside(0.0)
                model.Highlight_ShowOutline(0.0)
            }
            else
            {
                model.Highlight_HideOutline(0.0)
                model.Highlight_HideInside(0.0)
            }
}
