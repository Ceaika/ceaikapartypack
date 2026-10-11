global function Cl_GTFO_Init
global function GTFO_LaserShotFX

const vector GTFO_ORANGE = <1.0,0.30,0.08>
const vector GTFO_MINT = <0.27,0.92,0.75>
const vector GTFO_RED = <1.0,0.12,0.06>

struct
{
    var panelTopo = null
    var panelBack = null
    var accentTopo = null
    var accent = null
    var barTopo = null
    var barBack = null
    var fillTopo = null
    var fill = null
    var title = null
    var detail = null
    var lockon = null
    array<var> scoreTopos      // the hill-time counter: GTFO_SCORE_GLYPHS glyphs and their shadows
    array<var> score
    array<var> scoreShadow
    array<var> world
    array<var> worldTopos
    var waypoint = null
    int beep = -1
} gtfoHud

void function Cl_GTFO_Init()
{
    PrecacheWeapon("melee_gtfo_sword")
    PrecacheParticleSystem($"P_wpn_hand_laser_beam")
    ClGameState_RegisterGameStateAsset($"ui/gamestate_info_ffa.rpak")
    AddCallback_IsValidMeleeExecutionTarget(GTFO_CanExecute)
    thread GTFO_Presentation()
}

var function GTFO_Text(float size, vector color)
{
    var rui = CreateFullscreenRui($"ui/cockpit_console_text_top_left.rpak",111)
    RuiSetInt(rui,"maxLines",4)
    RuiSetInt(rui,"lineNum",0)
    RuiSetFloat(rui,"msgFontSize",size)
    RuiSetFloat(rui,"msgAlpha",0.0)
    RuiSetFloat(rui,"thicken",0.0)
    RuiSetFloat3(rui,"msgColor",color)
    return rui
}

var function GTFO_Rect(var topo, vector color, int sort)
{
    var rui = RuiCreate($"ui/basic_image.rpak",topo,RUI_DRAW_HUD,sort)
    RuiSetFloat3(rui,"basicImageColor",color)
    RuiSetFloat(rui,"basicImageAlpha",0.0)
    return rui
}

void function GTFO_Place(var topo, float x, float y, float w, float h)
{
    RuiTopology_UpdatePos(topo,<x,y,0>,<w,0,0>,<0,h,0>)
}

// Your hill time at the top of the screen, in the intro's font like Body
// Swap's countdown (PartyScore_Image in cl_party_names.nut),
// orange with the intro's shadow, mint while you are in the hill.
const int GTFO_SCORE_GLYPHS = 6               // up to "1234.5"
const float GTFO_SCORE_HEIGHT = 66.0           // digit height on a 1080p screen
const float GTFO_SCORE_TOP = 165.0             // from the top, clear of the score bar
const vector GTFO_SCORE_ORANGE = <0.9823,0.0704,0.0003>
const vector GTFO_SCORE_SHADOW = <0.18,0.004,0.0>

// The same card as the other party modes (Hot Potato, Juggernaut): a dark
// panel with a coloured edge, a title, a few lines of detail and a bar along
// the bottom. When the laser is locked on you, the game's own Amped Weapons
// crosshair countdown shows the time left, like Hot Potato's fuse.
bool function GTFO_HudCreate()
{
    array<var> topos
    for(int i=0;i<4+2*GTFO_SCORE_GLYPHS;i++)
    {
        var topo
        try { topo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false) }
        catch(ex) { foreach(var made in topos) RuiTopology_Destroy(made); return false }
        topos.append(topo)
    }
    for(int i=0;i<3;i++)
    {
        var topo
        try { topo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,true) }
        catch(ex) { foreach(var made in topos) RuiTopology_Destroy(made); foreach(var made in gtfoHud.worldTopos) RuiTopology_Destroy(made); gtfoHud.worldTopos.clear(); return false }
        gtfoHud.worldTopos.append(topo)
    }
    gtfoHud.panelTopo = topos[0]
    gtfoHud.panelBack = GTFO_Rect(topos[0],<0.015,0.02,0.03>,109)
    gtfoHud.accentTopo = topos[1]
    gtfoHud.accent = GTFO_Rect(topos[1],GTFO_ORANGE,110)
    gtfoHud.barTopo = topos[2]
    gtfoHud.barBack = GTFO_Rect(topos[2],<0.08,0.08,0.09>,110)
    gtfoHud.fillTopo = topos[3]
    gtfoHud.fill = GTFO_Rect(topos[3],GTFO_ORANGE,111)
    for(int i=0;i<GTFO_SCORE_GLYPHS;i++)
    {
        gtfoHud.scoreTopos.append(topos[4+2*i])
        gtfoHud.scoreShadow.append(GTFO_Rect(topos[4+2*i],GTFO_SCORE_SHADOW,120))
        gtfoHud.scoreTopos.append(topos[5+2*i])
        gtfoHud.score.append(GTFO_Rect(topos[5+2*i],GTFO_SCORE_ORANGE,121))
    }
    gtfoHud.title = GTFO_Text(30.0,<1.0,0.62,0.25>)
    gtfoHud.detail = GTFO_Text(19.0,<0.85,0.88,0.92>)
    gtfoHud.lockon = CreateCockpitRui($"ui/lockon_hud.rpak")
    RuiSetBool(gtfoHud.lockon,"isVisible",false)
    foreach(string side in ["northLock","southLock","westLock","eastLock"]) RuiSetBool(gtfoHud.lockon,side,false)
    foreach(var topo in gtfoHud.worldTopos)
    {
        var rui = RuiCreate($"ui/basic_image.rpak",topo,RUI_DRAW_WORLD,0)
        if(gtfoHud.world.len()<2) RuiSetImage(rui,"basicImage",$"rui/ceaika/gtfo_ring")
        RuiSetFloat(rui,"basicImageAlpha",0.0)
        gtfoHud.world.append(rui)
    }
    gtfoHud.waypoint = CreateCockpitRui($"ui/overhead_icon_evac.rpak",200)
    RuiSetImage(gtfoHud.waypoint,"icon",$"rui/ceaika/gtfo_ring")
    RuiSetGameTime(gtfoHud.waypoint,"finishTime",RUI_BADGAMETIME)
    RuiSetBool(gtfoHud.waypoint,"isVisible",false)
    return true
}

void function GTFO_HudDestroy()
{
    foreach(var rui in [gtfoHud.panelBack,gtfoHud.accent,gtfoHud.barBack,gtfoHud.fill,gtfoHud.title,gtfoHud.detail,gtfoHud.lockon,gtfoHud.waypoint])
        if(rui!=null) RuiDestroyIfAlive(rui)
    foreach(var rui in gtfoHud.world) RuiDestroyIfAlive(rui)
    foreach(var rui in gtfoHud.score) RuiDestroyIfAlive(rui)
    foreach(var rui in gtfoHud.scoreShadow) RuiDestroyIfAlive(rui)
    foreach(var topo in gtfoHud.scoreTopos) RuiTopology_Destroy(topo)
    gtfoHud.score.clear()
    gtfoHud.scoreShadow.clear()
    gtfoHud.scoreTopos.clear()
    foreach(var topo in [gtfoHud.panelTopo,gtfoHud.accentTopo,gtfoHud.barTopo,gtfoHud.fillTopo])
        if(topo!=null) RuiTopology_Destroy(topo)
    foreach(var topo in gtfoHud.worldTopos) RuiTopology_Destroy(topo)
    gtfoHud.world.clear()
    gtfoHud.worldTopos.clear()
    gtfoHud.panelTopo = null
    gtfoHud.waypoint = null
    gtfoHud.lockon = null
}

void function GTFO_DrawScore(float seconds,bool scoring)
{
    string text = seconds<0.0 ? "" : format("%.1f",seconds)
    float width = GetScreenSize()[0]
    float s = GetScreenSize()[1]/1080.0
    float h = GTFO_SCORE_HEIGHT*s
    // Laid out from the centre: total width first, glyphs lean right so they overlap a little.
    float total = 0.0
    for(int i=0;i<text.len();i++)
    {
        string glyph = text.slice(i,i+1)
        total += (glyph=="." ? h*21.0/150.0 : h)*PartyScore_Aspect(glyph)*0.94
    }
    float x = width*0.5-total*0.5
    float top = GTFO_SCORE_TOP*s
    for(int i=0;i<GTFO_SCORE_GLYPHS;i++)
    {
        var glyphRui = gtfoHud.score[i]
        var shadowRui = gtfoHud.scoreShadow[i]
        if(i>=text.len())
        {
            RuiSetFloat(glyphRui,"basicImageAlpha",0.0)
            RuiSetFloat(shadowRui,"basicImageAlpha",0.0)
            continue
        }
        string glyph = text.slice(i,i+1)
        float gh = glyph=="." ? h*21.0/150.0 : h
        float gw = gh*PartyScore_Aspect(glyph)
        float gy = top+h-gh
        RuiSetImage(glyphRui,"basicImage",PartyScore_Image(glyph))
        RuiSetImage(shadowRui,"basicImage",PartyScore_Image(glyph))
        RuiTopology_UpdatePos(gtfoHud.scoreTopos[2*i],<x+3.0*s,gy+4.0*s,0>,<gw,0,0>,<0,gh,0>)
        RuiTopology_UpdatePos(gtfoHud.scoreTopos[2*i+1],<x,gy,0>,<gw,0,0>,<0,gh,0>)
        RuiSetFloat3(glyphRui,"basicImageColor",scoring ? GTFO_MINT : GTFO_SCORE_ORANGE)
        RuiSetFloat(glyphRui,"basicImageAlpha",0.85)
        RuiSetFloat(shadowRui,"basicImageAlpha",0.5)
        x += gw*0.94
    }
}

void function GTFO_HudUpdate(entity player)
{
    int state = GetGlobalNetInt("gtfoState")
    int hill = GetGlobalNetInt("gtfoHill")
    bool visible = GetGameState()==eGameState.Playing
    bool live = visible && state==2
    entity target = GetGlobalNetEnt("gtfoTarget")
    bool locked = live && IsValid(target)
    bool mine = locked && target==player && IsAlive(player)
    bool scoring = live && player.GetPlayerNetBool("gtfoScoring")
    bool out = live && player.GetPlayerNetBool("gtfoOut")
    float left = max(0.0,GetGlobalNetTime("gtfoDeadline")-Time())
    vector center = GTFO_Center(hill)
    center.z = GTFO_Floor(hill)
    float meters = Distance(player.GetOrigin(),center)*0.0254

    // Locked on you: the game's crosshair countdown, beeping each second.
    RuiSetBool(gtfoHud.lockon,"isVisible",mine)
    if(mine)
    {
        RuiSetGameTime(gtfoHud.lockon,"lockEndTime",GetGlobalNetTime("gtfoDeadline"))
        RuiSetString(gtfoHud.lockon,"lockMessage",format("%.2f",left))
        int second = int(ceil(left))
        if(second!=gtfoHud.beep) EmitSoundOnEntity(player,"HUD_40mm_TrackerBeep_Locked")
        gtfoHud.beep = second
    }
    else gtfoHud.beep = -1

    string title = "GTFO"
    string detail = "Waiting for at least 2 pilots"
    vector accent = GTFO_ORANGE
    if(state==1)
    {
        title = format("ROUND STARTS IN %d",int(ceil(left)))
        detail = format("Head for hill %d",hill+1)
    }
    else if(live && out)
    {
        title = "ELIMINATED"
        detail = "Back next round"
    }
    else if(live && locked)
    {
        title = "LASER LOCKED"
        detail = mine ? "On you" : "On "+(target.IsPlayer() ? target.GetPlayerName() : "a pilot")
        accent = GTFO_RED
    }
    else if(live)
    {
        // Between locks: who is safest and who the laser will pick next.
        title = format("NEXT LASER IN %d",int(ceil(left)))
        array<entity> ranking
        foreach(entity p in GetPlayerArray())
            if(p.GetPlayerNetBool("gtfoInRound") && !p.GetPlayerNetBool("gtfoOut")) ranking.append(p)
        ranking.sort(int function(entity a,entity b) { return GTFO_GetTime(b)-GTFO_GetTime(a); })
        detail = ""
        if(ranking.len()>0) detail = format("Leading: %s (%.1fs)",ranking[0].GetPlayerName(),GTFO_GetTime(ranking[0])/100.0)
        if(ranking.len()>1)
        {
            entity risk = ranking[ranking.len()-1]
            detail += format("\nAt risk: %s (%.1fs)",risk.GetPlayerName(),GTFO_GetTime(risk)/100.0)
        }
    }

    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height/1080.0
    float x = width*0.025
    float y = height*0.29
    float w = 380.0*s
    int lines = split(detail,"\n").len()
    bool bar = live && !out
    if(detail=="") lines = 0
    float h = (54.0 + 24.0*lines + (bar ? 20.0 : 0.0))*s
    float alpha = visible ? 1.0 : 0.0
    GTFO_Place(gtfoHud.panelTopo,x,y,w,h)
    GTFO_Place(gtfoHud.accentTopo,x,y,4.0*s,h)
    RuiSetFloat(gtfoHud.panelBack,"basicImageAlpha",0.72*alpha)
    RuiSetFloat3(gtfoHud.accent,"basicImageColor",accent)
    RuiSetFloat(gtfoHud.accent,"basicImageAlpha",alpha)
    RuiSetString(gtfoHud.title,"msgText",title)
    RuiSetFloat2(gtfoHud.title,"msgPos",<(x+16.0*s)/width,(y+8.0*s)/height,0>)
    RuiSetFloat(gtfoHud.title,"msgAlpha",alpha)
    RuiSetFloat3(gtfoHud.detail,"msgColor",mine ? GTFO_RED : <0.85,0.88,0.92>)
    RuiSetString(gtfoHud.detail,"msgText",detail)
    RuiSetFloat2(gtfoHud.detail,"msgPos",<(x+16.0*s)/width,(y+44.0*s)/height,0>)
    RuiSetFloat(gtfoHud.detail,"msgAlpha",alpha)
    // The bar runs down to the next lock, or to the strike once someone is locked.
    float interval = locked ? clamp(GetCurrentPlaylistVarFloat("gtfo_laser_warning",3.0),1.0,10.0) : max(5.0,GetCurrentPlaylistVarFloat("gtfo_elimination_seconds",30.0))
    float bx = x+16.0*s
    float by = y+h-16.0*s
    float bw = w-32.0*s
    GTFO_Place(gtfoHud.barTopo,bx,by,bw,6.0*s)
    GTFO_Place(gtfoHud.fillTopo,bx,by,max(1.0,bw*clamp(left/interval,0.0,1.0)),6.0*s)
    RuiSetFloat(gtfoHud.barBack,"basicImageAlpha",bar ? 0.9 : 0.0)
    RuiSetFloat3(gtfoHud.fill,"basicImageColor",locked ? GTFO_RED : accent)
    RuiSetFloat(gtfoHud.fill,"basicImageAlpha",bar ? 1.0 : 0.0)

    GTFO_DrawScore(live && !out ? GTFO_GetTime(player)/100.0 : -1.0,scoring)

    // The hill: a marker overhead (it shows the distance itself) and the
    // scoring ring on the floor. The locked pilot: a red ring and beam.
    RuiSetBool(gtfoHud.waypoint,"isVisible",visible && state>0 && !scoring)
    RuiSetFloat3(gtfoHud.waypoint,"pos",center+<0,0,90>)
    RuiSetString(gtfoHud.waypoint,"statusText",format("Hill %d",hill+1))
    float r = GTFO_Radius()*1.05
    RuiTopology_UpdatePos(gtfoHud.worldTopos[0],center+< -r,-r,2>,<r*2,0,0>,<0,r*2,0>)
    RuiSetFloat3(gtfoHud.world[0],"basicImageColor",GTFO_MINT)
    RuiSetFloat(gtfoHud.world[0],"basicImageAlpha",visible && state>0 ? 0.7+0.15*sin(Time()*2.0) : 0.0)
    for(int i=1;i<3;i++) RuiSetFloat(gtfoHud.world[i],"basicImageAlpha",locked ? 0.85 : 0.0)
    if(locked)
    {
        vector pos = target.GetOrigin()+<0,0,3>
        RuiTopology_UpdatePos(gtfoHud.worldTopos[1],pos+< -55,-55,0>,<110,0,0>,<0,110,0>)
        RuiSetFloat3(gtfoHud.world[1],"basicImageColor",GTFO_RED)
        vector toward = player.EyePosition()-pos
        toward.z = 0.0
        vector side = Length(toward)>1.0 ? Normalize(CrossProduct(<0,0,1>,toward))*1.5 : <1.5,0,0>
        RuiTopology_UpdatePos(gtfoHud.worldTopos[2],pos-side,side*2,<0,0,800>)
        RuiSetFloat3(gtfoHud.world[2],"basicImageColor",GTFO_RED)
    }
}

void function GTFO_LaserShotFX(float x,float y,float z)
{
    thread GTFO_ShotFXThread(<x,y,z>)
}

void function GTFO_ShotFXThread(vector pos)
{
    vector impact = pos+<0,0,36>
    int fx = StartParticleEffectInWorldWithHandle(GetParticleSystemIndex($"P_wpn_hand_laser_beam"),impact+<0,0,3000>,<90,0,0>)
    EffectSetControlPointVector(fx,1,impact)
    OnThreadEnd(void function() : (fx)
    {
        if(EffectDoesExist(fx)) EffectStop(fx,true,false)
        printt("[GTFO] Ion shot cleared")
    })
    wait 0.30
}

void function GTFO_Presentation()
{
    while(!IsValid(GetLocalClientPlayer())) WaitFrame()
    while(GetGameState()<eGameState.Playing) wait 0.1
    OnThreadEnd(void function() { GTFO_HudDestroy(); })
    while(!GTFO_HudCreate()) wait 1.0
    while(true)
    {
        entity player = GetLocalClientPlayer()
        if(IsValid(player)) GTFO_HudUpdate(player)
        wait 0.05
    }
}
