untyped
global function EchoScan_ScanTarget
global function EchoScan_Init
global function EchoScan_Clear
global function EchoScan_Screech
global function EchoScan_DecoyMotion
global function EchoScan_NoiseAt
global function EchoScan_Noise
global function EchoScan_AudibleJump
global function EchoScan_HasReturns
global function EchoScan_SetBlind
global function EchoScan_Visibility
struct
{
    bool blind = false
    table<entity,float> airRevealUntil
    table<entity,table> scanned
    array<table> noises
    array<table> pulses
    array<asset> models
    entity boundary = null
    entity guideLight = null
    entity roleLight = null
    bool guidance = false
    int boundaryIndex = -1
    float visibility = 0.0
    float nextNoise = 0.0
} scan
void function EchoScan_Init()
{
    scan.models=Echo_BoundaryModels()
    thread EchoScan_Update()
}
void function EchoScan_SetBlind(bool blind)
{
    if(blind==scan.blind) return
    scan.blind=blind
    var environment=GetLightEnvironmentEntity()
    if(IsValid(environment)) environment.ScaleSunSkyIntensity(blind ? 0.0 : 1.0,blind ? 0.0 : 1.0)
}
// u cant Hide() a networked player on the client. everything below only touches client made echoes
void function EchoScan_Clear()
{
    foreach(table pulse in scan.pulses) EchoScan_DestroyPulse(pulse)
    scan.pulses.clear()
    foreach(table noise in scan.noises)
    {
        if(IsValid(noise.light)) noise.light.Destroy()
        if(IsValid(noise.echo)) noise.echo.Destroy()
    }
    scan.noises.clear()
    foreach(entity source,table entry in scan.scanned) if(IsValid(entry.model)) entry.model.Destroy()
    scan.scanned.clear()
    scan.airRevealUntil.clear()
    if(IsValid(scan.guideLight)) scan.guideLight.Destroy()
    scan.guideLight=null
    if(IsValid(scan.roleLight)) scan.roleLight.Destroy()
    scan.roleLight=null
    scan.guidance=false
    if(IsValid(scan.boundary)) scan.boundary.Destroy()
    scan.boundary=null
    scan.boundaryIndex=-1
    scan.visibility=0.0
    scan.nextNoise=Time()+0.75
}
bool function EchoScan_HasReturns()
{
    return scan.pulses.len()>0 && !scan.guidance && scan.visibility>0.0 && IsValid(scan.boundary)
}
float function EchoScan_Visibility() { return scan.visibility; }
bool function EchoScan_CanSee()
{
    entity p=GetLocalClientPlayer()
    return IsValid(p) && IsAlive(p) && !p.IsObserver() && GetLocalViewPlayer()==p && GetGameState()==eGameState.Playing && p.GetPlayerNetBool("echoHunter") && p.GetPlayerNetBool("echoActive") && GetGlobalNetInt("echoPhase")==2
}
void function EchoScan_Screech(vector origin,float radius,float travel)
{
    if(!EchoScan_CanSee()) return
    foreach(table pulse in scan.pulses) EchoScan_DestroyPulse(pulse)
    scan.pulses.clear()
    foreach(entity source,table entry in scan.scanned) if(IsValid(entry.model)) entry.model.Destroy()
    scan.scanned.clear()
    EchoScan_Pulse(GetLocalClientPlayer().EyePosition(),radius,travel,true)
}
void function EchoScan_Noise(entity source,float radius,float travel,float strength=1.0,bool trail=false,bool silhouette=true,bool continuous=false)
{
    if(!IsValid(source)) return
    // low overlapping volumes mark the floor along a run, they stay where they were placed
    vector origin=source.GetOrigin()+<0,0,24>
    if(trail) radius=clamp(radius,112.0,144.0)
    EchoScan_NoiseAt(origin,radius,travel,source,strength,false,silhouette,continuous)
}
void function EchoScan_NoiseAt(vector origin,float radius,float travel,entity source=null,float strength=1.0,bool decoy=false,bool silhouette=true,bool continuous=false,int decoyId=-1)
{
    if(GetCurrentPlaylistVarInt("echo_noise_debug",0)>0) print("[ECHO-PATCH] requested origin="+origin+" canSee="+EchoScan_CanSee())
    if(!EchoScan_CanSee()) return
    if(Distance(GetLocalClientPlayer().EyePosition(),origin)>GetCurrentPlaylistVarFloat("echo_noise_range",3072.0)) return
    // a grunt or melee while running cant interrupt the moving echo
    bool following=silhouette && IsValid(source) && (continuous || EchoScan_HasMovingEcho(source)) && EchoScan_NoisyMovement(source)
    // 12 light slots reused. quiet ones get set black every frame or u get permanent dots everywhere.
    // the permanent dots bug haunted me for like 3 days
    int choice=-1
    float oldest=Time()+1.0
    foreach(int i,table noise in scan.noises)
    {
        if(!noise.active) { choice=i; break; }
        if(noise.start<oldest) { oldest=expect float(noise.start); choice=i; }
    }
    if(scan.noises.len()<12 && (choice<0 || scan.noises[choice].active))
    {
        scan.noises.append({light=CreateClientSideDynamicLight(origin,<0,0,0>,<0,0,0>,1.0),active=false,start=0.0,origin=origin,radius=0.0,grow=0.0,echo=null,source=null,strength=1.0,logged=false,shown=false,context=0,nextHighlight=0.0,seen=-1.0,nextSight=0.0,decoy=false,following=false,nextPose=0.0,decoyId=-1,decoyPose=-1,moveFrom=origin,moveTo=origin,moveAt=0.0,moveUntil=0.0,decoyAnimAt=0.0,decoyAnimDuration=1.0,nextTrail=0.0})
        choice=scan.noises.len()-1
    }
    // one hider moving cant wipe everyone else's sound history
    int sourceCount=0
    int sourceOldest=-1
    float sourceTime=Time()+1.0
    if(IsValid(source)) foreach(int i,table slot in scan.noises)
    {
        if(slot.active && slot.source==source)
        {
            sourceCount++
            if(slot.start<sourceTime) { sourceTime=expect float(slot.start); sourceOldest=i; }
        }
    }
    int history=maxint(3,minint(8,GetCurrentPlaylistVarInt("echo_trail_samples",6)))
    if(sourceCount>=history) choice=sourceOldest
    if(decoy && decoyId<0) foreach(int i,table slot in scan.noises)
        if(slot.active && slot.decoy && DistanceSqr(origin,slot.origin)<32.0*32.0) { choice=i; break; }
    table noise=scan.noises[choice]
    if(IsValid(noise.echo)) noise.echo.Destroy()
    noise.echo=null
    noise.shown=false
    noise.nextHighlight=0.0
    noise.logged=false
    noise.source=source
    noise.decoy=decoy
    noise.decoyId=decoyId
    noise.decoyPose=-1
    noise.nextTrail=Time()+0.5
    noise.moveUntil=0.0
    noise.following=following && !decoy
    noise.nextPose=Time()+0.1
    noise.strength=clamp(strength,0.15,1.0)
    noise.origin=origin
    noise.radius=clamp(radius,32.0,320.0)
    noise.grow=clamp(travel,0.1,1.0)
    noise.start=Time()
    noise.seen=-1.0
    noise.nextSight=0.0
    noise.active=true
    noise.light.SetOrigin(origin)
    if(silhouette && IsValid(source) && source!=GetLocalClientPlayer() && (!source.IsPlayer() || !source.GetPlayerNetBool("echoHunter")))
        EchoScan_CapturePose(noise,source)
    else if(decoy) EchoScan_CaptureDecoy(noise)
    if(GetCurrentPlaylistVarInt("echo_noise_debug",0)>0) print("[ECHO-PATCH] slots="+scan.noises.len()+" radius="+noise.radius+" source="+origin)
}
void function EchoScan_AudibleJump(entity source)
{
    if(!IsValid(source) || !EchoScan_CanSee()) return
    if(Length2D(source.GetVelocity())<GetCurrentPlaylistVarFloat("echo_sprint_speed",220.0)) return
    // only a heard sprint jump opens this, just seeing someone doesnt
    scan.airRevealUntil[source] <- Time()+clamp(GetCurrentPlaylistVarFloat("echo_jump_reveal_seconds",0.9),0.1,2.0)
}
bool function EchoScan_NoisyMovement(entity source)
{
    if(!IsValid(source) || !source.IsPlayer() || !IsAlive(source) || !source.GetPlayerNetBool("echoActive") || source.GetPlayerNetBool("echoHunter")) return false
    if(source.IsZiplining()) return true
    if(source.IsTraversing()) return false
    bool shoved=Time()<source.GetPlayerNetTime("echoShovedUntil")
    if(source.GetPlayerNetBool("echoQuiet") && !shoved) return false
    if(source in scan.airRevealUntil)
    {
        if(source.IsOnGround() || Time()>=scan.airRevealUntil[source]) delete scan.airRevealUntil[source]
        else return true
    }
    return (source.IsOnGround() || source.IsWallRunning()) && Length2D(source.GetVelocity())>GetCurrentPlaylistVarFloat("echo_walk_speed",35.0)
}
bool function EchoScan_HasMovingEcho(entity source)
{
    foreach(table noise in scan.noises)
        if(noise.active && noise.following && noise.source==source && IsValid(noise.echo)) return true
    return false
}
void function EchoScan_UpdateMovingEcho(table noise)
{
    if(!noise.following) return
    entity source=expect entity(noise.source)
    if(!EchoScan_NoisyMovement(source))
    {
        // keep the last audible frame's pose, never sample the new quiet position
        noise.following=false
        noise.seen=-1.0
        noise.nextSight=0.0
        return
    }
    if(Time()>=noise.nextPose)
    {
        // pose snapshots dont care about footsteps or framerate
        EchoScan_CapturePose(noise,source)
        noise.nextPose=Time()+0.1
        noise.nextHighlight=0.0
    }
    if(IsValid(noise.echo))
    {
        noise.echo.SetOrigin(source.GetOrigin())
        noise.echo.SetAngles(source.GetAngles())
    }
    // continuous sound stays revealed at any distance, once quiet it expires 5s after u see it
    noise.seen=-1.0
}
bool function EchoScan_NoiseVisible(vector eye,vector origin,float radius)
{
    entity viewer=GetLocalClientPlayer()
    vector forward=AnglesToForward(viewer.EyeAngles())
    float[2] screen=GetScreenSize()
    array<vector> offsets=[<0,0,0>,<1,0,0>,< -1,0,0>,<0,1,0>,<0,-1,0>,<0,0,1>,<0,0,-1>]
    foreach(vector offset in offsets)
    {
        vector point=origin+offset*radius*0.7
        if(DotProduct(point-eye,forward)<=0.0) continue
        var pixel=Hud.ToScreenSpace(point)
        if(pixel[0]<0 || pixel[0]>=screen[0] || pixel[1]<0 || pixel[1]>=screen[1]) continue
        vector direction=Normalize(point-eye)
        TraceResults trace=TraceLine(eye,point+direction*radius,viewer,TRACE_MASK_PLAYERSOLID | TRACE_MASK_BLOCKLOS,TRACE_COLLISION_GROUP_NONE)
        // a clear ray into the sky isnt a dot, needs to actually hit a surface
        if(!trace.startSolid && trace.fraction<1.0 && Distance(trace.endPos,origin)<radius) return true
    }
    return false
}
// radius needed to see far sound patches, everything else stays black
float function EchoScan_UpdateNoises(vector eye)
{
    float extent=0.0
    foreach(table noise in scan.noises)
    {
        if(!IsValid(noise.light)) continue
        if(noise.active) { EchoScan_UpdateMovingEcho(noise); EchoScan_UpdateDecoy(noise); }
        float age=Time()-expect float(noise.start)
        // clue expires 5s after u actually see it on screen, being close isnt enough
        float linger=max(0.1,GetCurrentPlaylistVarFloat("echo_noise_seen_linger",5.0))
        float radius=max(1.0,noise.radius*clamp(age/noise.grow,0.0,1.0))
        if(noise.active && noise.seen<0.0 && Time()>=noise.nextSight)
        {
            noise.nextSight=Time()+0.1
            if(EchoScan_NoiseVisible(eye,expect vector(noise.origin),radius)) noise.seen=Time()
        }
        float sinceSeen=noise.seen<0.0 ? -1.0 : Time()-expect float(noise.seen)
        if(!noise.active || sinceSeen>=linger)
        {
            noise.active=false
            if(IsValid(noise.echo)) noise.echo.Destroy()
            noise.echo=null
            noise.light.SetLightColor(<0,0,0>)
            noise.light.SetLightRadius(1.0)
            continue
        }
        float alpha=sinceSeen<0.0 ? 1.0 : clamp((linger-sinceSeen)/min(1.0,linger),0.0,1.0)
        noise.light.SetLightRadius(radius)
        noise.light.SetLightColor(<1,0.25,0.0625>*alpha*noise.strength)
        if(IsValid(noise.echo) && Time()>=noise.nextHighlight)
        {
            // single sounds freeze, continuous movement follows every frame. walls dont hide it
            noise.echo.Show()
            noise.echo.Highlight_SetParam(noise.context,0,<1.4,0.025,0.015>*alpha*noise.strength)
            noise.echo.Highlight_SetCurrentContext(noise.context)
            noise.echo.Highlight_ResetFlags()
            noise.echo.Highlight_SetVisibilityType(HIGHLIGHT_VIS_ALWAYS)
            noise.echo.Highlight_SetNearFadeDist(0.0)
            noise.echo.Highlight_SetFarFadeDist(100000.0)
            noise.echo.Highlight_SetFadeInTime(noise.following ? 0.0 : 0.1)
            noise.echo.Highlight_SetFadeOutTime(0.1)
            noise.echo.Highlight_SetLifeTime(Time()+20.0)
            noise.echo.Highlight_StartOn()
            noise.echo.Highlight_ShowOutline(0.0)
            noise.echo.Highlight_ShowInside(0.0)
            noise.nextHighlight=Time()+0.1
        }
        extent=max(extent,Distance(eye,noise.origin)+radius+16.0)
    }
    return extent
}
void function EchoScan_Pulse(vector origin,float radius,float travel,bool screech)
{
    radius=clamp(radius,32.0,1024.0)
    travel=clamp(travel,0.1,6.0)
    float hold=max(0.0,screech ? GetCurrentPlaylistVarFloat("echo_pulse_hold",7.0) : GetCurrentPlaylistVarFloat("echo_noise_pulse_hold",5.0))
    float fade=screech ? 1.5 : 0.8
    var light=CreateClientSideDynamicLight(origin,<0,0,0>,<0,0,0>,8.0)
    table pulse={light=light,origin=origin,start=Time(),grow=travel,hold=hold,fade=fade,radius=radius,screech=screech,metadata=[]}
    if(screech) EchoScan_Capture(pulse)
    scan.pulses.append(pulse)
}
void function EchoScan_Update()
{
    OnThreadEnd(function() { EchoScan_Clear(); EchoScan_SetBlind(false); })
    while(true)
    {
        if(!EchoScan_CanSee())
        {
            if(IsValid(scan.roleLight) || IsValid(scan.boundary) || IsValid(scan.guideLight) || scan.pulses.len()>0 || scan.noises.len()>0) EchoScan_Clear()
            WaitFrame()
            continue
        }
        array<entity> expiredJumps
        foreach(entity source,float until in scan.airRevealUntil)
            if(!IsValid(source) || !IsAlive(source) || Time()>=until) expiredJumps.append(source)
        foreach(entity source in expiredJumps) delete scan.airRevealUntil[source]
        entity p=GetLocalClientPlayer()
        // heartbeat so dead light slots cant leave the material override stuck on
        if(!IsValid(scan.roleLight)) scan.roleLight=CreateClientSideDynamicLight(p.EyePosition(),<0,0,0>,<0.015625,0.0625,0.03125>,8192.0+Time()*8.0)
        scan.roleLight.SetOrigin(p.EyePosition())
        scan.roleLight.SetLightRadius(8192.0+Time()*8.0)
        // tiny dim volume at the feet as a fallback. two shells hide each other so dont add another one
        vector origin=p.GetOrigin()+<0,0,16>
        int guideIndex=int(floor(clamp(GetCurrentPlaylistVarFloat("echo_guidance_radius",160.0),64.0,192.0)/16.0))-1
        float guideRadius=(guideIndex+1)*16.0
        float brightness=clamp(GetCurrentPlaylistVarFloat("echo_guidance_brightness",0.5),0.125,1.0)
        // self lit dots on the ground, no shading
        vector lightOrigin=p.GetOrigin()+<0,0,48>
        if(!IsValid(scan.guideLight)) scan.guideLight=CreateClientSideDynamicLight(lightOrigin,<0,0,0>,<0.0625,0.25,1>*brightness,guideRadius)
        scan.guideLight.SetOrigin(lightOrigin)
        scan.guideLight.SetLightRadius(guideRadius)
        scan.guideLight.SetLightColor(<0.0625,0.25,1>*brightness)
        int index=guideIndex
        scan.visibility=brightness
        scan.guidance=true
        if(scan.pulses.len()>0)
        {
            table pulse=scan.pulses[0]
            float age=Time()-expect float(pulse.start)
            if(!IsValid(pulse.light) || age>=pulse.grow+pulse.hold+pulse.fade)
            {
                EchoScan_DestroyPulse(pulse)
                scan.pulses.clear()
                scan.nextNoise=Time()+0.75
            }
            else
            {
                float growth=clamp(age/max(0.05,pulse.grow),0.0,1.0)
                float alpha=1.0-clamp((age-pulse.grow-pulse.hold)/max(0.05,pulse.fade),0.0,1.0)
                float power=pulse.screech ? 1.0 : 0.65
                int pulseIndex=int(clamp(floor(pulse.radius*growth/16.0)-1,0,scan.models.len()-1))
                float radius=(pulseIndex+1)*16.0
                pulse.light.SetLightRadius(radius)
                // green channel = growth/hold state, white crest only while expanding
                float waveFlag=growth<1.0 ? 0.0625 : 0.10
                pulse.light.SetLightColor((pulse.screech ? <0.25,waveFlag,1> : <0.0625,0.25,1>)*alpha*power)
                if(pulse.screech)
                {
                    foreach(entity meta in pulse.metadata) if(IsValid(meta)) meta.SetLightRadius(8192.0+Time()*8.0)
                }
                float distance=Distance(p.EyePosition(),pulse.origin)
                float visible=alpha*clamp((radius*0.98-distance)/24.0,0.0,1.0)
                if(distance<radius*0.98 && pulseIndex>=guideIndex)
                {
                    origin=expect vector(pulse.origin)
                    index=pulseIndex
                    scan.visibility=visible
                    scan.guidance=false
                }
            }
        }
        EchoScan_UpdateScanned()
        float noiseExtent=EchoScan_UpdateNoises(p.EyePosition())
        if(noiseExtent>0.0)
        {
            float extent=max(noiseExtent,Distance(p.EyePosition(),origin)+(index+1)*16.0)
            origin=p.EyePosition()
            index=int(clamp(ceil(extent/16.0)-1,guideIndex,scan.models.len()-1))
        }
        if(!IsValid(scan.boundary)) scan.boundary=CreateClientSidePropDynamic(origin,<0,0,0>,scan.models[index])
        else if(index!=scan.boundaryIndex) scan.boundary.SetModel(scan.models[index])
        scan.boundary.SetOrigin(origin)
        scan.boundaryIndex=index
        WaitFrame()
    }
}

void function EchoScan_DestroyPulse(table pulse)
{
    if(IsValid(pulse.light)) pulse.light.Destroy()
    foreach(entity light in pulse.metadata) if(IsValid(light)) light.Destroy()
}
void function EchoScan_Capture(table pulse)
{
    entity p=GetLocalClientPlayer()
    vector eye=expect vector(pulse.origin)
    vector angles=p.EyeAngles()
    vector forward=AnglesToForward(angles)
    vector right=AnglesToRight(angles)
    vector up=AnglesToUp(angles)
    float[2] screen=GetScreenSize()
    var center=Hud.ToScreenSpace(eye+forward*256.0)
    var edgeX=Hud.ToScreenSpace(eye+forward*256.0+right*64.0)
    var edgeY=Hud.ToScreenSpace(eye+forward*256.0+up*64.0)
    float tanX=clamp(screen[0]*0.125/max(1.0,fabs(float(edgeX[0])-float(center[0]))),0.2,4.0)
    float tanY=clamp(screen[1]*0.125/max(1.0,fabs(float(edgeY[1])-float(center[1]))),0.2,4.0)
    pulse.forward <- forward; pulse.right <- right; pulse.up <- up; pulse.tanX <- tanX; pulse.tanY <- tanY
    pulse.metadata.append(CreateClientSideDynamicLight(eye+right*tanX*256.0,<0,0,0>,<0.5,0.03125,0.125>,8192.0+Time()*8.0))
    pulse.metadata.append(CreateClientSideDynamicLight(eye+up*tanY*256.0,<0,0,0>,<0.25,0.03125,0.25>,8192.0+Time()*8.0))
    print("[ECHO-CONE] captured eye="+eye+" angles="+angles+" tanFov="+tanX+","+tanY+" depthMask=off")
}

void function EchoScan_CaptureDecoy(table noise)
{
    // borrow an already loaded pilot pose
    entity template=GetLocalClientPlayer()
    foreach(entity p in GetPlayerArray())
        if(IsValid(p) && IsAlive(p) && p.GetPlayerNetBool("echoActive") && !p.GetPlayerNetBool("echoHunter")) { template=p; break; }
    if(!IsValid(template)) return
    entity dummy=CreateClientSidePropDynamicClone(template,template.GetModelName())
    if(!IsValid(dummy)) return
    dummy.Hide()
    vector origin=expect vector(noise.origin)
    TraceResults ground=TraceLine(origin+<0,0,32>,origin-<0,0,256>,GetLocalClientPlayer(),TRACE_MASK_PLAYERSOLID | TRACE_MASK_BLOCKLOS,TRACE_COLLISION_GROUP_NONE)
    vector feet=!ground.startSolid && ground.fraction<1.0 ? ground.endPos : origin-<0,0,24>
    // CapturePose copies a temp source so it cant wipe the real hider's echo
    EchoScan_CapturePose(noise,dummy)
    if(IsValid(noise.echo))
    {
        noise.echo.SetOrigin(feet)
        noise.echo.SetAngles(<0,GetLocalClientPlayer().EyeAngles().y,0>)
        // sample a sprint stride then freeze it like a real sound echo
        foreach(string sequence in ["Sprint_mp_forward","Run_forward_mp"])
        {
            if(!noise.echo.Anim_HasSequence(sequence)) continue
            noise.echo.Anim_Play(sequence)
            noise.echo.Anim_SetPaused(false)
            noise.echo.SetCycle(0.35)
            noise.echo.SetPlaybackRate(0.0)
            break
        }
    }
    dummy.Destroy()
}
void function EchoScan_CapturePose(table noise,entity source)
{
    // latest pose per source, old patches keep their own timers
    foreach(table old in scan.noises)
        if(old!=noise && old.source==source && IsValid(old.echo)) { old.echo.Destroy(); old.echo=null; old.following=false; }
    if(IsValid(noise.echo)) noise.echo.Destroy()
    noise.echo=null
    if(noise.following && source in scan.scanned && IsValid(scan.scanned[source].model))
    {
        scan.scanned[source].model.Destroy()
        scan.scanned[source].model=null
    }
    entity echo=CreateClientSidePropDynamicClone(source,source.GetModelName())
    if(!IsValid(echo)) return
    echo.SetOrigin(noise.origin-<0,0,24>)
    echo.Highlight_SetInheritHighlight(false)
    echo.Anim_SetPaused(false)
    echo.SetPlaybackRate(0.0)
    int context=5 // HIGHLIGHT_CONTEXT_CLIENT; independent of copied player state.
    noise.context=context
    echo.Highlight_SetCurrentContext(context)
    echo.Highlight_SetFunctions(context,109,true,101,2.5,0,true)
    echo.Highlight_SetParam(context,0,<1.4,0.025,0.015>*noise.strength)
    echo.Highlight_SetFarFadeDist(100000.0)
    echo.Highlight_SetNearFadeDist(0.0)
    echo.Highlight_SetFadeInTime(0.1)
    echo.Highlight_SetFadeOutTime(0.1)
    echo.Highlight_SetVisibilityType(HIGHLIGHT_VIS_ALWAYS)
    echo.Highlight_ShowOutline(0.0)
    echo.Highlight_ShowInside(0.0)
    echo.Highlight_StartOn()
    echo.Hide()
    if(noise.following)
    {
        // frequent snapshots cant spend a frame hidden or keep restarting the fade in
        echo.Highlight_ResetFlags()
        echo.Highlight_SetVisibilityType(HIGHLIGHT_VIS_ALWAYS)
        echo.Highlight_SetFadeInTime(0.0)
        echo.Highlight_SetLifeTime(Time()+20.0)
        echo.Show()
    }
    noise.echo=echo
    if(GetCurrentPlaylistVarInt("echo_noise_debug",0)>0) print("[ECHO-POSE] captured origin="+echo.GetOrigin()+" cycle="+echo.GetCycle())
}

bool function EchoScan_ScanContains(entity source)
{
    if(!IsValid(source) || !EchoScan_CanSee() || scan.pulses.len()==0) return false
    vector point=source.GetOrigin()+<0,0,36>
    if(Distance(GetLocalClientPlayer().EyePosition(),point)>GetCurrentPlaylistVarFloat("echo_outline_range",320.0)) return false
    table pulse=scan.pulses[0]
    vector delta=point-expect vector(pulse.origin)
    float radius=expect float(pulse.radius)*clamp((Time()-expect float(pulse.start))/expect float(pulse.grow),0.0,1.0)
    float forward=DotProduct(delta,expect vector(pulse.forward))
    return Length(delta)<radius && forward>0.0 && fabs(DotProduct(delta,expect vector(pulse.right)))<forward*expect float(pulse.tanX) && fabs(DotProduct(delta,expect vector(pulse.up)))<forward*expect float(pulse.tanY)
}
void function EchoScan_ScanTarget(entity source)
{
    if(!EchoScan_ScanContains(source)) return
    table pulse=scan.pulses[0]
    if(source in scan.scanned) return // One frozen pose per screech, never live tracking.
    scan.scanned[source] <- {model=null,origin=source.GetOrigin()+<0,0,36>}
    if(EchoScan_HasMovingEcho(source)) return // Avoid a second, lagging scan pose.
    table entry=scan.scanned[source]
    entity model=CreateClientSidePropDynamicClone(source,source.GetModelName())
    if(!IsValid(model)) return
    entry.model=model
    model.Highlight_SetInheritHighlight(false)
    model.Anim_SetPaused(false)
    model.SetPlaybackRate(0.0)
    int context=5
    model.Highlight_SetFunctions(context,0,true,101,2.5,0,true)
    model.Highlight_SetParam(context,0,<1.4,0.025,0.015>)
    model.Highlight_SetCurrentContext(context)
    model.Highlight_ResetFlags()
    model.Highlight_SetVisibilityType(HIGHLIGHT_VIS_ALWAYS)
    model.Highlight_SetNearFadeDist(0.0)
    model.Highlight_SetFarFadeDist(100000.0)
    model.Highlight_SetFadeInTime(0.0)
    model.Highlight_SetFadeOutTime(0.0)
    model.Highlight_SetLifeTime(Time()+20.0)
    model.Highlight_StartOn()
    model.Highlight_HideInside(0.0)
    model.Highlight_ShowOutline(0.0)
    model.Show()
}
void function EchoScan_UpdateScanned()
{
    foreach(entity p in GetPlayerArray())
        if(IsValid(p) && p!=GetLocalClientPlayer() && IsAlive(p) && p.GetPlayerNetBool("echoActive") && !p.GetPlayerNetBool("echoHunter")) EchoScan_ScanTarget(p)
    array<entity> stale
    foreach(entity source,table entry in scan.scanned)
    {
        if(scan.pulses.len()==0 || !IsValid(source) || (source.IsPlayer() && (!IsAlive(source) || !source.GetPlayerNetBool("echoActive") || source.GetPlayerNetBool("echoHunter"))))
            stale.append(source)
        else if(IsValid(entry.model)) entry.model.Show() // Once revealed, distance never hides the frozen pose.
    }
    foreach(entity source in stale)
    {
        if(IsValid(scan.scanned[source].model)) scan.scanned[source].model.Destroy()
        delete scan.scanned[source]
    }
}

// one echo model per decoy, packets just move it
void function EchoScan_DecoyMotion(int id,vector feet,float yaw,int pose)
{
    if(!EchoScan_CanSee()) return
    table found={}
    foreach(table slot in scan.noises)
        if(slot.active && slot.decoy && slot.decoyId==id) { found=slot;break; }
    if(found.len()==0)
    {
        EchoScan_NoiseAt(feet+<0,0,24>,144.0,0.2,null,0.85,true,true,false,id)
        foreach(table slot in scan.noises)
            if(slot.active && slot.decoy && slot.decoyId==id) { found=slot;break; }
        if(found.len()==0) return
        found.moveFrom=feet;found.moveTo=feet
    }
    if(!IsValid(found.echo)) return
    vector previous=expect vector(found.moveTo)
    found.moveFrom=found.echo.GetOrigin()
    found.moveTo=feet
    found.moveAt=Time()
    found.moveUntil=Time()+0.15
    found.echo.SetAngles(<0,yaw,0>)
    found.seen=-1.0
    found.nextSight=0.0
    if(pose!=found.decoyPose)
    {
        found.decoyPose=pose
        string sequence=pose==0 ? "Sprint_mp_forward" : pose==1 ? "Slide_forward_mp" : "CQB_CrouchIdle_MP"
        if(found.echo.Anim_HasSequence(sequence))
        {
            found.echo.Anim_Play(sequence)
            found.echo.Anim_SetPaused(false)
            found.echo.SetPlaybackRate(0.0)
            found.decoyAnimAt=Time()
            found.decoyAnimDuration=max(0.1,found.echo.GetSequenceDuration(sequence))
        }
        if(GetCurrentPlaylistVarInt("echo_noise_debug",0)>0) print("[ECHO-DECOY-POSE] id="+id+" sequence="+sequence+" valid="+found.echo.Anim_HasSequence(sequence))
    }
    // a few still floor patches look like a trail. shares the 12 slot cap
    if(pose<2 && Time()>=found.nextTrail && DistanceSqr(previous,feet)>1.0)
    {
        found.nextTrail=Time()+0.5
        EchoScan_NoiseAt(previous+<0,0,24>,120.0,0.2,null,0.55,false,false)
    }
}
void function EchoScan_UpdateDecoy(table noise)
{
    if(!noise.decoy || noise.decoyId<0 || !IsValid(noise.echo)) return
    float blend=clamp((Time()-expect float(noise.moveAt))/0.1,0.0,1.0)
    vector from=expect vector(noise.moveFrom)
    vector to=expect vector(noise.moveTo)
    vector feet=from+(to-from)*blend
    noise.echo.SetOrigin(feet)
    noise.origin=feet+<0,0,24>
    noise.light.SetOrigin(noise.origin)
    if(Time()<=noise.moveUntil)
    {
        float age=Time()-expect float(noise.decoyAnimAt)
        float cycle=age/expect float(noise.decoyAnimDuration)
        // run loops, slide settles low, freeze when packets stop
        noise.echo.SetCycle(noise.decoyPose==0 ? cycle-floor(cycle) : min(0.7,cycle))
        if(noise.decoyPose<2) noise.seen=-1.0
    }
}
