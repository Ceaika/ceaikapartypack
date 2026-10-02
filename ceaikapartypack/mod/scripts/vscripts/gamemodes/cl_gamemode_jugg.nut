untyped
global function Cl_GamemodeJugg_Init
global function JuggBatteryEvent
global function JuggBatteryHealFeedback
global function JuggFinaleWarning
global function JuggChanceUpdate
global function JuggTitanHUDMetadata
global function JuggPowerHealthUpdate
global function JuggDamageFlyout

const JUGG_HIGHLIGHT_CONTEXT_ENEMY = 2

vector juggFinaleOrigin = <0,0,0>
int juggFinaleRadius = 0
int juggFinaleRound = -1
void function JuggFinaleWarning(float x,float y,float z,int radius)
{
    juggFinaleOrigin = <x,y,z>
    juggFinaleRadius = radius
    juggFinaleRound = GetGlobalNetInt("juggRound")
}

float juggHealFeedbackUntil = 0.0
int juggHealFeedbackRound = -1
int juggHealHull = 0
int juggHealShield = 0
void function JuggBatteryHealFeedback(int hullAdded,int shieldAdded)
{
    entity player = GetLocalClientPlayer()
    if (!IsValid(player) || !IsAlive(player) || !player.IsTitan()) return
    juggHealHull = hullAdded
    juggHealShield = shieldAdded
    juggHealFeedbackRound = GetGlobalNetInt("juggRound")
    juggHealFeedbackUntil = Time()+2.5
    PartyUI_Popup("BATTERY COLLECTED",format("+%s hull  /  +%s shield",JuggComma(hullAdded),JuggComma(shieldAdded)),<0.3,0.92,0.58>,2 )

}

table<entity,array<int> > juggPowerHealth
int juggPowerHealthRound = -1
void function JuggPowerHealthUpdate(int handle,int health,int maximum)
{
    if (juggPowerHealthRound != GetGlobalNetInt("juggRound"))
    {
        juggPowerHealth.clear()
        juggPowerHealthRound = GetGlobalNetInt("juggRound")
    }
    entity power = GetEntityFromEncodedEHandle(handle)
    if (IsValid(power)) juggPowerHealth[power] <- [health,maximum]
}

int juggHUDShieldMax = 0
int juggHUDSegments = 1
int juggHUDAegis = 0
int juggHUDMetadataRound = -1
bool juggHUDDoomed = false
void function JuggTitanHUDMetadata(int shieldMax,int segments,int aegis,bool doomed)
{
    juggHUDShieldMax = maxint(0,shieldMax)
    juggHUDSegments = maxint(1,segments)
    juggHUDAegis = minint(3,maxint(0,aegis))
    juggHUDDoomed = doomed
    juggHUDMetadataRound = GetGlobalNetInt("juggRound")
}

int juggChanceTickets = 0
void function JuggChanceUpdate(int tickets) { juggChanceTickets = tickets; }

void function Cl_GamemodeJugg_Init()
{
    JuggHackClientInit()
    foreach (int team in [TEAM_IMC,TEAM_MILITIA])
    {
        RegisterLevelMusicForTeam(eMusicPieceID.LEVEL_THREE_MINUTE,"music_mp_freeagents_almostdone",team)
        RegisterLevelMusicForTeam(eMusicPieceID.LEVEL_WIN,"music_mp_freeagents_outro_win",team)
        RegisterLevelMusicForTeam(eMusicPieceID.LEVEL_LOSS,"music_mp_freeagents_outro_lose",team)
        RegisterLevelMusicForTeam(eMusicPieceID.LEVEL_DRAW,"music_mp_freeagents_outro_lose",team)
        RegisterLevelMusicForTeam(eMusicPieceID.GAMEMODE_1,"music_mp_fd_midwave",team)
        RegisterLevelMusicForTeam(eMusicPieceID.GAMEMODE_2,"music_skyway_01_intro",team)
        RegisterLevelMusicForTeam(eMusicPieceID.LEVEL_LAST_MINUTE,"music_mp_titanwar_lastminute",team)
    }
	AddCreateCallback( "item_titan_battery", JuggOnBatteryCreated )
	thread JuggTerminalIconsThink()
	thread JuggHUDThink()
    thread JuggBossBarThink()
    thread JuggCoreIconThink()
    thread JuggSpecialFXThink()
    thread JuggAegisHUDThink()
    thread JuggOutlineThink()
    thread JuggSabotageViewThink()
}

void function JuggOnBatteryCreated( entity battery )
{
	thread JuggBatteryIcon( battery )
}

void function JuggBatteryIcon( entity battery )
{
	battery.EndSignal( "OnDestroy" )

	while ( !IsValid( GetLocalViewPlayer() ) )
		WaitFrame()
	var rui = CreateCockpitRui( $"ui/fra_battery_icon.rpak" )
	RuiSetGameTime( rui, "startTime", Time() )
	RuiTrackFloat3( rui, "pos", battery, RUI_TRACK_OVERHEAD_FOLLOW )
	OnThreadEnd( function() : ( rui ) { RuiDestroyIfAlive( rui ); } )
	while ( true )
	{

		RuiSetBool( rui, "isVisible", !IsValid( battery.GetParent() ) && GetGameState() == eGameState.Playing )
		wait 0.1
	}
}

struct
{
    var cardTopo
    var card
    var accentTopo
    var accent
    var barTopo
    var bar
    var fillTopo
    var fill
    var heading
    var clock
    var status
    var eventName
    var eventDetail
    var chance
    var damage

    string title = ""
    string timer = ""
    string detail = ""
    string eventTitle = ""
    string eventSubtitle = ""
    vector accentColor = <0.35,0.82,1.0>
    vector timerColor = <0.95,0.97,1.0>
    vector statusColor = <0.78,0.84,0.9>
    float clockAlpha = 0.95
    float progress = -1.0
    int progressKey = -1
    float progressTotal = 1.0
} juggHud

var function JuggHudText(float size,vector color)
{
    var rui = CreateFullscreenRui($"ui/cockpit_console_text_top_left.rpak",100)
    RuiSetInt(rui,"maxLines",4)
    RuiSetInt(rui,"lineNum",0)
    RuiSetFloat(rui,"msgAlpha",0.95)
    RuiSetFloat(rui,"thicken",0.0)
    RuiSetFloat(rui,"msgFontSize",size)
    RuiSetFloat3(rui,"msgColor",color)
    return rui
}
var function JuggHudRect(var topo,vector color,float alpha,int sort)
{
    var rui = RuiCreate($"ui/basic_image.rpak",topo,RUI_DRAW_HUD,sort)
    RuiSetFloat3(rui,"basicImageColor",color)
    RuiSetFloat(rui,"basicImageAlpha",alpha)
    return rui
}
void function JuggHudPlace(var topo,float x,float y,float w,float h)
{
    RuiTopology_UpdatePos(topo,<x,y,0>,<w,0,0>,<0,h,0>)
}

void function JuggHUDThink()
{
    while (!IsValid(GetLocalClientPlayer())) WaitFrame()
    juggHud.cardTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggHud.card = JuggHudRect(juggHud.cardTopo,<0.015,0.02,0.03>,0.0,98)
    juggHud.accentTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggHud.accent = JuggHudRect(juggHud.accentTopo,<0.35,0.82,1.0>,0.0,99)
    juggHud.barTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggHud.bar = JuggHudRect(juggHud.barTopo,<0.1,0.11,0.13>,0.0,99)
    juggHud.fillTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggHud.fill = JuggHudRect(juggHud.fillTopo,<0.35,0.82,1.0>,0.0,100)
    juggHud.heading = JuggHudText(18.0,<0.35,0.82,1.0>)
    juggHud.clock = JuggHudText(40.0,<0.95,0.97,1.0>)
    juggHud.status = JuggHudText(18.0,<0.78,0.84,0.9>)
    juggHud.eventName = JuggHudText(17.0,<1.0,0.67,0.27>)
    juggHud.eventDetail = JuggHudText(15.0,<0.78,0.84,0.9>)
    juggHud.chance = JuggHudText(15.0,<0.25,0.9,0.8>)
    juggHud.damage = JuggHudText(15.0,<1.0,0.85,0.55>)
    OnThreadEnd(function() {
        foreach (rui in [juggHud.card,juggHud.accent,juggHud.bar,juggHud.fill,juggHud.heading,juggHud.clock,
            juggHud.status,juggHud.eventName,juggHud.eventDetail,juggHud.chance,juggHud.damage]) RuiDestroyIfAlive(rui)
        foreach (topo in [juggHud.cardTopo,juggHud.accentTopo,juggHud.barTopo,juggHud.fillTopo]) RuiTopology_Destroy(topo)
    })
    while (true)
    {
        JuggHudCompute(GetLocalClientPlayer())
        JuggHudDraw()
        wait 0.1
    }
}

void function JuggHudCompute(entity player)
{
    juggHud.title = ""
    juggHud.timer = ""
    juggHud.detail = ""
    juggHud.accentColor = <0.35,0.82,1.0>
    juggHud.timerColor = <0.95,0.97,1.0>
    juggHud.statusColor = <0.78,0.84,0.9>
    juggHud.clockAlpha = 0.95
    juggHud.progress = -1.0
    int phase = GetGlobalNetInt("juggPhase")
    if (IsValid(player) && GetGameState() == eGameState.Playing)
    {
        bool boss = player.GetPlayerNetBool("juggIsBoss")
        float left = GetGlobalNetTime("juggRoundEnd")-Time()
        int remaining = maxint(0,int(ceil(left)))
        if (boss) juggHud.accentColor = <1.0,0.67,0.27>
        if (phase == 2)
        {
            juggHud.title = (boss ? "JUGGERNAUT  -  SURVIVE" : "HUNTER  -  TAKE IT DOWN") + "  /  ROUND " + GetGlobalNetInt("juggRound")
            if (GetGlobalNetInt("juggRounds") > 0) juggHud.title += "/" + GetGlobalNetInt("juggRounds")
            juggHud.timer = format("%d:%02d",remaining/60,remaining%60)
            if (remaining <= 30) juggHud.timerColor = <1.0,0.35,0.25>

            int key = GetGlobalNetInt("juggRound")
            if (key != juggHud.progressKey || left > juggHud.progressTotal) { juggHud.progressKey = key; juggHud.progressTotal = max(1.0,left); }
            juggHud.progress = clamp(left/juggHud.progressTotal,0.0,1.0)
            if (!IsAlive(player) && !boss)
            {
                float respawn = player.GetPlayerNetTime("juggRespawnAt")
                juggHud.detail = respawn > 0.0 ? "REDEPLOY IN " + maxint(0,int(ceil(respawn-Time()))) + "s" : "WAITING FOR WAVE"
            }
            else if (!boss) JuggHudHunterStatus(player)
            if (left > 0.0 && left <= 10.0)
            {
                juggHud.clockAlpha = int(Time()*4)%2 == 0 ? 1.0 : 0.2
                juggHud.timerColor = <1.0,0.15,0.1>
            }
        }
        else if (phase == 5)
        {
            juggHud.title = "JUGGERNAUT VICTORY"
            juggHud.timer = "DETONATION  " + remaining
            juggHud.detail = boss ? "VICTORY  /  NUCLEAR EJECT" : "RUN  /  COVER WON'T SAVE YOU"
            if (!boss && juggFinaleRound == GetGlobalNetInt("juggRound") && juggFinaleRadius > 0)
            {
                float escape = juggFinaleRadius-Distance(player.GetOrigin(),juggFinaleOrigin)
                juggHud.detail = escape >= 0.0 ? "RUN  /  " + int(ceil(escape)) + " UNITS TO SAFETY" : "SAFE  /  STAY OUT OF THE BLAST"
                juggHud.statusColor = escape >= 0.0 ? <1.0,0.2,0.1> : <0.2,1.0,0.5>
            }
            juggHud.timerColor = int(Time()*4)%2 == 0 ? <1.0,0.2,0.1> : <1.0,0.65,0.2>
        }
        else if (phase == 1) { juggHud.title = "ROLE DRAW"; juggHud.timer = int(Time()*5)%2 == 0 ? "HUNTER" : "JUGGERNAUT"; juggHud.detail = "Choosing the Juggernaut"; }
        else if (phase == 3) { juggHud.title = "INTERMISSION"; juggHud.timer = format("%d:%02d",remaining/60,remaining%60); juggHud.detail = "Next round starting soon"; }
        else { juggHud.title = "JUGGERNAUT"; juggHud.detail = "Waiting for players"; }
    }
    JuggHudExtras(player,phase)
}

void function JuggHudHunterStatus(entity player)
{
    float bounds = player.GetPlayerNetTime("juggOutOfBoundsAt")-Time()
    if (bounds > 0.0)
    {
        juggHud.detail = "RETURN TO COMBAT  /  " + int(ceil(bounds)) + "s"
        juggHud.statusColor = <1.0,0.3,0.2>
    }
    else if (player.GetPlayerNetTime("juggBatteryExpiresAt") > Time())
    {
        juggHud.detail = "HOLDING BATTERY  /  " + int(ceil(player.GetPlayerNetTime("juggBatteryExpiresAt")-Time())) + "s  -  STAY ALIVE"
        juggHud.statusColor = <0.3,0.92,0.58>
    }
    else if (player.GetPlayerNetTime("juggOverchargeEnd") > Time()) juggHud.detail = "AMPED WEAPONS  /  " + int(ceil(player.GetPlayerNetTime("juggOverchargeEnd")-Time())) + "s"
    else if (player.GetPlayerNetInt("juggBoost") > 0) juggHud.detail = JuggBoostLine(player.GetPlayerNetInt("juggBoost")-1)
}

string function JuggBoostLine(int reward)
{
    array<string> names = ["AMPED WEAPONS","DOUBLE TETHER","TICK STRIKE","CHARGE RIFLE","STALKER PODS","TITAN CHALLENGE","SABOTAGE BATTERY"]
    string name = reward >= 0 && reward < names.len() ? names[reward] : "BOOST"
    return name + "  /  PRESS BOOST"
}

void function JuggHudExtras(entity player,int phase)
{
    juggHud.eventTitle = ""
    juggHud.eventSubtitle = ""
    if (phase != 2 || !IsValid(player)) return
    if (!player.IsTitan())
    {
        foreach (entity weapon in player.GetMainWeapons())
            if (IsValid(weapon) && weapon.GetWeaponClassName() == "mp_weapon_defender" && player.GetPlayerNetTime("juggSmokeReadyAt") > Time())
                juggHud.detail += (juggHud.detail == "" ? "" : "\n") + "CHARGE RIFLE  /  " + int(ceil(player.GetPlayerNetTime("juggSmokeReadyAt")-Time())) + "s"
    }
    if (player.GetPlayerNetTime("juggEmergencyShieldEnd") > Time()) juggHud.detail += "\nSHIELD OVERRIDE  /  " + int(ceil(player.GetPlayerNetTime("juggEmergencyShieldEnd")-Time())) + "s"
    else if (player.GetPlayerNetBool("juggEmergencyShieldReady")) juggHud.detail += "\nSHIELD OVERRIDE READY  /  PRESS BOOST"
    else if (player.GetPlayerNetBool("juggIsBoss") && juggHUDMetadataRound == GetGlobalNetInt("juggRound") && juggHUDAegis == 3) juggHud.detail += "\nSHIELD OVERRIDE USED"
    if (GetGlobalNetTime("juggDuelEnd") > Time()) juggHud.detail += "\nTITAN DUEL  /  " + int(ceil(GetGlobalNetTime("juggDuelEnd")-Time())) + "s"
    array<string> specials = ["","LOW GRAVITY","TWIN JUGGERNAUTS","OVERDRIVE","UNLIMITED ABILITIES","","CORE COMBAT","FAST PILOTS","AIR CONTROL","BOTTOMLESS MAGAZINES"]
    array<string> descriptions = ["","Gravity reduced to 40%","Two Titans at half health","Unlimited pilot abilities dashes","No cooldowns for anyone","","Laser Core only, always charged","Pilots move twice as fast","Full air control for pilots","Magazines never run dry"]
    int special = GetGlobalNetInt("juggSpecial")
    if (special > 0 && special < specials.len()) { juggHud.eventTitle = "SPECIAL  /  " + specials[special]; juggHud.eventSubtitle = descriptions[special]; }
    if (player.IsTitan() && player.GetPlayerNetTime("juggSabotageEnd") > Time())
    {
        juggHud.detail = "SABOTAGED  /  " + int(ceil(player.GetPlayerNetTime("juggSabotageEnd")-Time())) + "s"
        juggHud.statusColor = <1.0,0.3,0.2>
    }

    if (juggHud.detail.find("\n") == 0) juggHud.detail = juggHud.detail.slice(1)
}

void function JuggHudDraw()
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height/1080.0
    float w = 420.0*s
    float x = min(clamp(GetConVarFloat("jugg_hud_x"),0.0,0.76)*width,width-w-8.0*s)
    float y = clamp(GetConVarFloat("jugg_hud_y"),0.0,0.72)*height
    bool shown = juggHud.title != ""
    int statusLines = juggHud.detail == "" ? 0 : split(juggHud.detail,"\n").len()

    float statusY = y + (juggHud.timer == "" ? 38.0 : (juggHud.progress >= 0.0 ? 100.0 : 86.0))*s
    float eventY = statusY + (statusLines*23.0 + (statusLines > 0 ? 8.0 : 0.0))*s

    string damage = shown ? JuggCardDamageLine() : ""
    float damageY = eventY + (juggHud.eventTitle != "" ? 52.0 : 0.0)*s
    float chanceY = damageY + (damage != "" ? 23.0 : 0.0)*s
    float h = chanceY - y + 30.0*s
    JuggHudPlace(juggHud.cardTopo,x,y,w,h)
    JuggHudPlace(juggHud.accentTopo,x,y,4.0*s,h)
    RuiSetFloat(juggHud.card,"basicImageAlpha",shown ? 0.66 : 0.0)
    RuiSetFloat3(juggHud.accent,"basicImageColor",juggHud.accentColor)
    RuiSetFloat(juggHud.accent,"basicImageAlpha",shown ? 1.0 : 0.0)
    float barW = w-32.0*s
    JuggHudPlace(juggHud.barTopo,x+16.0*s,y+84.0*s,barW,5.0*s)
    JuggHudPlace(juggHud.fillTopo,x+16.0*s,y+84.0*s,max(1.0,barW*max(0.0,juggHud.progress)),5.0*s)
    RuiSetFloat(juggHud.bar,"basicImageAlpha",shown && juggHud.progress >= 0.0 ? 0.9 : 0.0)
    RuiSetFloat3(juggHud.fill,"basicImageColor",juggHud.progress >= 0.0 && juggHud.progress < 0.15 ? <1.0,0.3,0.2> : juggHud.accentColor)
    RuiSetFloat(juggHud.fill,"basicImageAlpha",shown && juggHud.progress >= 0.0 ? 1.0 : 0.0)
    JuggHudLine(juggHud.heading,juggHud.title,juggHud.accentColor,0.95,x+16.0*s,y+10.0*s,width,height)
    JuggHudLine(juggHud.clock,juggHud.timer,juggHud.timerColor,juggHud.clockAlpha,x+16.0*s,y+30.0*s,width,height)
    JuggHudLine(juggHud.status,juggHud.detail,juggHud.statusColor,0.95,x+16.0*s,statusY,width,height)
    JuggHudLine(juggHud.eventName,juggHud.eventTitle,<1.0,0.67,0.27>,0.95,x+16.0*s,eventY,width,height)
    JuggHudLine(juggHud.eventDetail,juggHud.eventSubtitle,<0.78,0.84,0.9>,0.95,x+16.0*s,eventY+22.0*s,width,height)
    JuggHudLine(juggHud.damage,damage,<1.0,0.85,0.55>,0.95,x+16.0*s,damageY,width,height)
    JuggHudLine(juggHud.chance,shown ? format("NEXT JUGGERNAUT CHANCE  /  %.2f%%",juggChanceTickets/100.0) : "",<0.25,0.9,0.8>,0.95,x+16.0*s,chanceY,width,height)
}

void function JuggHudLine(var rui,string text,vector color,float alpha,float x,float y,float width,float height)
{
    RuiSetString(rui,"msgText",text)
    RuiSetFloat3(rui,"msgColor",color)
    RuiSetFloat(rui,"msgAlpha",text == "" ? 0.0 : alpha)
    RuiSetFloat2(rui,"msgPos",<x/width,y/height,0>)
}

void function JuggTerminalIconsThink()
{
    table<entity, bool> tracked
    while (true)
    {
        array<entity> stale
        foreach (entity crate, bool unused in tracked)
            if (!IsValid(crate)) stale.append(crate)
        foreach (entity crate in stale) delete tracked[crate]
        array<entity> objectives = GetEntArrayByScriptName("jugg_terminal_power")
        objectives.extend(GetEntArrayByScriptName("jugg_boost_terminal"))
        foreach (entity crate in objectives)
        {
            if (!IsValid(crate) || crate in tracked) continue
            tracked[crate] <- true
            thread JuggTerminalIcon(crate)
        }
        wait 1.0
    }
}

void function JuggTerminalIcon(entity crate)
{
    crate.EndSignal("OnDestroy")
    bool power = GetEntArrayByScriptName("jugg_terminal_power").contains(crate)
    string activeName = power ? "jugg_terminal_power" : "jugg_boost_terminal"
    while (!IsValid(GetLocalViewPlayer())) WaitFrame()
    var rui = CreateCockpitRui($"ui/overhead_icon_generic.rpak",MINIMAP_Z_BASE-20)
    var label = CreateFullscreenRui($"ui/cockpit_console_text_top_left.rpak",100)

    var backTopo = power ? RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false) : null
    var fillTopo = power ? RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false) : null
    var back = power ? RuiCreate($"ui/basic_image.rpak",backTopo,RUI_DRAW_HUD,101) : null
    var fill = power ? RuiCreate($"ui/basic_image.rpak",fillTopo,RUI_DRAW_HUD,102) : null
    if (power)
    {
        RuiSetFloat3(back,"basicImageColor",<0.08,0.10,0.12>)
        RuiSetFloat(back,"basicImageAlpha",0.9)
        RuiSetFloat(fill,"basicImageAlpha",1.0)
        RuiSetDrawGroup(back,RUI_DRAW_NONE)
        RuiSetDrawGroup(fill,RUI_DRAW_NONE)
    }
    OnThreadEnd(function() : (rui,label,back,fill,backTopo,fillTopo) {
        RuiDestroyIfAlive(rui)
        RuiDestroyIfAlive(label)
        if (back != null) RuiDestroyIfAlive(back)
        if (fill != null) RuiDestroyIfAlive(fill)
        if (backTopo != null) RuiTopology_Destroy(backTopo)
        if (fillTopo != null) RuiTopology_Destroy(fillTopo)
    })
    RuiSetImage(rui,"icon",$"rui/hud/gametype_icons/fd/coop_harvester")
    RuiSetBool(rui,"pinToEdge",true)
    RuiSetBool(rui,"showClampArrow",true)
    RuiSetBool(rui,"isVisible",false)
    RuiSetFloat2(rui,"iconSize",<40,40,0>)
    RuiSetInt(label,"maxLines",2)
    RuiSetInt(label,"lineNum",0)
    RuiSetFloat(label,"thicken",0.0)
    RuiSetFloat(label,"msgFontSize",18.0)
    RuiSetFloat(label,"msgAlpha",0.0)
    RuiSetFloat3(label,"msgColor",power ? <1.0,0.45,0.25> : <0.25,0.9,0.8>)
    while (GetEntArrayByScriptName(activeName).contains(crate))
    {
        entity player = GetLocalClientPlayer()
        bool visible = IsValid(player) && IsAlive(player) && GetLocalViewPlayer() == player && GetGameState() == eGameState.Playing && GetGlobalNetInt("juggPhase") == 2
        if (visible && !power) visible = !player.IsTitan() && !player.GetPlayerNetBool("juggIsBoss")
        RuiSetBool(rui,"isVisible",visible)
        RuiSetFloat(label,"msgAlpha",0.0)
        if (power)
        {
            RuiSetDrawGroup(back,RUI_DRAW_NONE)
            RuiSetDrawGroup(fill,RUI_DRAW_NONE)
        }
        if (visible)
        {
            vector pos = crate.GetOrigin()+<0,0,100>
            RuiSetFloat3(rui,"pos",pos)
            float distance = Distance(player.GetOrigin(),crate.GetOrigin())
            float size = GraphCapped(distance,160.0,2500.0,44.0,32.0)
            RuiSetFloat2(rui,"iconSize",<size,size,0>)

            if (DotProduct(player.GetViewVector(),pos-player.EyePosition()) > 0.0)
            {
                array screen = expect array(Hud.ToScreenSpace(pos))
                float x = float(screen[0])/GetScreenSize()[0]
                float y = float(screen[1])/GetScreenSize()[1]
                if (x > 0.06 && x < 0.90 && y > 0.04 && y < 0.90)
                {
                    RuiSetFloat2(label,"msgPos",<x-0.025,y+0.025,0>)
                    string text = "HACK"
                    if (power)
                    {
                        text = player.IsTitan() ? "DESTROY" : "HARVESTER"
                        if (crate in juggPowerHealth)
                        {
                            float fraction = clamp(juggPowerHealth[crate][0].tofloat()/maxint(1,juggPowerHealth[crate][1]),0.0,1.0)
                            float width = GetScreenSize()[0]*0.07
                            float height = max(5.0,GetScreenSize()[1]*0.007)
                            vector origin = <float(screen[0])-width*0.5,float(screen[1])+GetScreenSize()[1]*0.05,0>
                            RuiTopology_UpdatePos(backTopo,origin,<width,0,0>,<0,height,0>)
                            RuiTopology_UpdatePos(fillTopo,origin+<1,1,0>,<max(0.1,(width-2)*fraction),0,0>,<0,height-2,0>)
                            RuiSetFloat3(fill,"basicImageColor",<1.0-fraction,0.2+0.6*fraction,fraction>)
                            RuiSetDrawGroup(back,RUI_DRAW_HUD)
                            RuiSetDrawGroup(fill,fraction > 0.0 ? RUI_DRAW_HUD : RUI_DRAW_NONE)
                        }
                    }
                    RuiSetString(label,"msgText",text)
                    RuiSetFloat(label,"msgAlpha",1.0)
                }
            }
        }
        WaitFrame()
    }
}

void function JuggTerminalPromptThink()
{
    while (!IsValid(GetLocalViewPlayer())) WaitFrame()
    var prompt = CreateFullscreenRui($"ui/cockpit_console_text_top_left.rpak",110)
    RuiSetInt(prompt,"maxLines",2)
    RuiSetInt(prompt,"lineNum",0)
    RuiSetFloat(prompt,"thicken",0.0)
    RuiSetFloat(prompt,"msgFontSize",20.0)
    RuiSetFloat3(prompt,"msgColor",<0.25,0.9,0.8>)
    RuiSetFloat2(prompt,"msgPos",<0.38,0.68,0>)
    OnThreadEnd(function() : (prompt) { RuiDestroyIfAlive(prompt); })
    while (true)
    {
        string text = ""
        entity player = GetLocalClientPlayer()
        if (IsValid(player) && IsAlive(player) && !player.IsTitan() && GetLocalViewPlayer() == player && GetGlobalNetInt("juggPhase") == 2)
        {
            foreach (entity panel in GetEntArrayByScriptName("jugg_boost_terminal"))
            {
                if (DistanceSqr(player.GetOrigin(),panel.GetOrigin()) > 220*220) continue
                if (DotProduct(player.GetViewVector(),Normalize(panel.GetOrigin()+<0,0,48>-player.EyePosition())) < 0.5) continue
                if (player.GetPlayerNetInt("juggBoost") > 0) text = "USE YOUR BOOST FIRST"
                else if (!expect bool(ControlPanel_CanUseFunction(player,panel))) text = "FACE THE SCREEN TO HACK"
                else text = Localize("#JUGG_TERMINAL_HACK") + "  /  ARROWS HACK FASTER"
                break
            }
        }
        RuiSetString(prompt,"msgText",text)
        RuiSetFloat(prompt,"msgAlpha",text == "" ? 0.0 : 1.0)
        wait 0.1
    }
}

void function JuggAegisHUDThink()
{
    var panel = null
    int shownTier = -1
    int shownRound = -1
    array<var> ownedPanel = [null]
    OnThreadEnd(function() : (ownedPanel) { if (ownedPanel[0] != null) RuiDestroyIfAlive(ownedPanel[0]); })
    while (true)
    {
        entity player = GetLocalClientPlayer()
        bool visible = IsValid(player) && IsAlive(player) && player.IsTitan() && GetLocalViewPlayer() == player && GetGameState() == eGameState.Playing && GetGlobalNetInt("juggPhase") == 2 && player.GetPlayerNetBool("juggIsBoss") && juggHUDMetadataRound == GetGlobalNetInt("juggRound") && juggHUDAegis > 0
        if (!visible)
        {
            if (panel != null) { RuiDestroyIfAlive(panel); panel = null; ownedPanel[0] = null; }
            shownTier = -1
            wait 0.1
            continue
        }
        if (panel == null)
        {
            panel = CreateTitanCockpitRui($"ui/ajax_cockpit_fd.rpak")
            ownedPanel[0] = panel

            RuiSetFloat(panel,"ejectManualTimeOut",EJECT_FADE_TIME)
            RuiSetFloat(panel,"ejectButtonTimeOut",TITAN_EJECT_MAX_PRESS_DELAY)
            RuiSetGameTime(panel,"ejectManualStartTime",-60.0)
            RuiSetDrawGroup(panel,RUI_DRAW_COCKPIT)
            TitanLoadoutDef loadout = GetActiveTitanLoadout(player)
            var icon = GetIconForTitanClass(loadout.titanClass)
            RuiSetImage(panel,"titanIcon",icon)
            for (int i=1;i<=7;i++)
            {
                RuiSetImage(panel,"upgradeIcon"+i,icon)
                string label = i == 1 ? "Shield capacity +50%" : (i <= 3 ? "Combat upgrade " + (i-1) : "")
                RuiSetString(panel,"upgradeName"+i,label)
            }
        }
        int round = GetGlobalNetInt("juggRound")
        if (shownTier != juggHUDAegis || shownRound != round)
        {
            RuiSetBool(panel,"isFirstBoot",true)
            RuiSetInt(panel,"titanRank",juggHUDAegis)
            RuiSetInt(panel,"maxActiveIndex",juggHUDAegis)
            RuiSetGameTime(panel,"updateTime",Time())
            if (juggHUDAegis > 0 && (shownRound != round || juggHUDAegis > shownTier))
                EmitSoundOnEntity(player,"UI_InGame_FD_MetaUpgradeAnnouncement")
            shownTier = juggHUDAegis
            shownRound = round
        }
        wait 0.1
    }
}

void function JuggOutlineThink()
{
    while(true)
    {
        entity viewer=GetLocalViewPlayer()
        foreach(entity boss in GetPlayerArray())
        {
            if(!IsValid(viewer) || !IsAlive(boss) || !boss.IsTitan() || boss.GetTeam()!=TEAM_IMC || viewer.GetTeam()==boss.GetTeam()) continue
            bool show=GetCurrentPlaylistVarInt("jugg_always_marked",1)==1 && GetGlobalNetInt("juggPhase")==2 && Time()>=GetGlobalNetTime("juggOutlineAt") && viewer.GetTeam()!=boss.GetTeam() && DistanceSqr(viewer.GetOrigin(),boss.GetOrigin())>500*500
            boss.Highlight_SetCurrentContext(JUGG_HIGHLIGHT_CONTEXT_ENEMY)

            boss.Highlight_ResetFlags()
            boss.Highlight_SetNearFadeDist(0.0)
            boss.Highlight_SetFarFadeDist(32000.0)
            boss.Highlight_SetVisibilityType(HIGHLIGHT_VIS_ALWAYS)

            if(show)
            {
                boss.Highlight_SetFadeInTime(0.0)
                boss.Highlight_SetFadeOutTime(0.05)
                boss.Highlight_SetLifeTime(0.2)
                boss.Highlight_StartOn()
                boss.Highlight_ShowOutline(0.0)
            }
            else boss.Highlight_HideOutline(0.0)
        }
        wait 0.1
    }
}

void function JuggSabotageViewThink()
{
    RunUIScript("JuggSetSabotageInput",false)
    OnThreadEnd(function() { RunUIScript("JuggSetSabotageInput",false); })
    while(true)
    {
        entity player=GetLocalClientPlayer()
        bool active=IsValid(player) && IsAlive(player) && player.IsTitan() && GetGlobalNetInt("juggPhase")==2 && Time()<player.GetPlayerNetTime("juggSabotageEnd")
        RunUIScript("JuggSetSabotageInput",active)
        wait 0.05
    }
}

int juggBatteryEventType=0
float juggBatteryEventUntil=0.0
int juggBatteryEventRound=-1
void function JuggBatteryEvent(int event)
{
    juggBatteryEventType=event
    juggBatteryEventUntil=Time()+3.0
    juggBatteryEventRound=GetGlobalNetInt("juggRound")
    if(event==1) PartyUI_Popup("BATTERY STOLEN","Hold it for 5 seconds to deny the heal",<0.3,0.92,0.58>,2 ,3.0)
    else if(event==2) PartyUI_Popup("BATTERY DENIED","The Titan lost that heal | +1 point",<0.3,0.92,0.58>,2 )

    else if(event==3 || event==4) thread JuggCockpitBurst($"P_MFD_unmark",1.5,"")
}

const int JUGG_FLYOUT_MAX = 8
struct JuggFlyout
{
    var rui
    float born = -99.0
    float x = 0.0
    float drift = 0.0
    int amount = 0
}
struct
{
    var shieldTopo
    var shield
    var trackTopo
    var track
    var trailTopo
    var trail
    var hullTopo
    var hull
    var aegisTrackTopo
    var aegisTrack
    var aegisFillTopo
    var aegisFill
    var name
    var percent
    var aegisText
    array<JuggFlyout> flyouts
    int nextFlyout = 0
    float trailFrac = 1.0
    float hullFrac = 1.0
    float trailHoldUntil = 0.0
    float lastDraw = 0.0
    int shownTier = 0
    float tierFlashUntil = 0.0
    int myRound = -1
    int myTotal = 0
    int myNext = 0
    int myTier = 0
} juggBar

void function JuggDamageFlyout(int amount,int total,int next,int tier)
{
    juggBar.myRound = GetGlobalNetInt("juggRound")
    juggBar.myTotal = total
    juggBar.myNext = next
    juggBar.myTier = tier
    if (amount <= 0 || juggBar.flyouts.len() == 0) return
    int i = juggBar.nextFlyout
    juggBar.nextFlyout = (i+1) % juggBar.flyouts.len()
    juggBar.flyouts[i].born = Time()
    juggBar.flyouts[i].amount = amount
    juggBar.flyouts[i].drift = (i%2 == 0 ? 1.0 : -1.0)*RandomFloatRange(0.3,1.0)
    juggBar.flyouts[i].x = juggBar.hullFrac
}

string function JuggComma(int value)
{
    string digits = string(maxint(0,value))
    string result = ""
    for (int i = 0; i < digits.len(); i++)
    {
        if (i > 0 && (digits.len()-i) % 3 == 0) result += ","
        result += digits.slice(i,i+1)
    }
    return result
}

string function JuggCardDamageLine()
{
    entity player = GetLocalClientPlayer()
    if (!IsValid(player) || player.IsTitan() || GetGlobalNetInt("juggPhase") != 2 || juggBar.myRound != GetGlobalNetInt("juggRound")) return ""
    string line = "YOUR DAMAGE  " + JuggComma(juggBar.myTotal)
    if (juggBar.myNext <= 0) return line + "  /  MAX RANK"
    return line + "  /  " + (juggBar.myTier == 0 ? "VETERAN AT " : "VANGUARD AT ") + JuggComma(juggBar.myNext)
}

var function JuggBarText(asset kind,float size,vector color,int sort)
{
    var rui = CreateFullscreenRui(kind,sort)
    RuiSetInt(rui,"maxLines",1)
    RuiSetInt(rui,"lineNum",0)
    RuiSetFloat(rui,"thicken",0.0)
    RuiSetFloat(rui,"msgFontSize",size)
    RuiSetFloat3(rui,"msgColor",color)
    RuiSetFloat(rui,"msgAlpha",0.0)
    return rui
}

var function JuggBarRect(var topo,vector color,int sort)
{
    return JuggHudRect(topo,color,0.0,sort)
}

void function JuggBarCreate()
{
    asset LEFT = $"ui/cockpit_console_text_top_left.rpak"
    asset CENTER = $"ui/cockpit_console_text_center.rpak"
    juggBar.shieldTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggBar.shield = JuggBarRect(juggBar.shieldTopo,<0.45,0.85,1.0>,92)
    juggBar.trackTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggBar.track = JuggBarRect(juggBar.trackTopo,<0.04,0.045,0.05>,90)
    juggBar.trailTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggBar.trail = JuggBarRect(juggBar.trailTopo,<1,1,1>,91)
    juggBar.hullTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggBar.hull = JuggBarRect(juggBar.hullTopo,<1.0,0.62,0.28>,92)
    juggBar.aegisTrackTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggBar.aegisTrack = JuggBarRect(juggBar.aegisTrackTopo,<0.04,0.045,0.05>,90)
    juggBar.aegisFillTopo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    juggBar.aegisFill = JuggBarRect(juggBar.aegisFillTopo,<1.0,0.72,0.3>,92)
    juggBar.name = JuggBarText(LEFT,16.0,<0.92,0.93,0.95>,95)
    juggBar.percent = JuggBarText(CENTER,16.0,<0.92,0.93,0.95>,95)
    juggBar.aegisText = JuggBarText(LEFT,13.0,<1.0,0.72,0.3>,95)
    for (int i = 0; i < JUGG_FLYOUT_MAX; i++)
    {
        JuggFlyout flyout
        flyout.rui = JuggBarText(CENTER,17.0,<1,1,1>,96)
        RuiSetFloat(flyout.rui,"thicken",0.2)
        juggBar.flyouts.append(flyout)
    }
}

void function JuggBossBarThink()
{
    while (!IsValid(GetLocalClientPlayer())) WaitFrame()
    JuggBarCreate()
    OnThreadEnd(function() {
        array ruis = [juggBar.shield,juggBar.track,juggBar.trail,juggBar.hull,juggBar.aegisTrack,juggBar.aegisFill,juggBar.name,juggBar.percent,juggBar.aegisText]
        foreach (JuggFlyout flyout in juggBar.flyouts) ruis.append(flyout.rui)
        foreach (rui in ruis) RuiDestroyIfAlive(rui)
        foreach (topo in [juggBar.shieldTopo,juggBar.trackTopo,juggBar.trailTopo,juggBar.hullTopo,juggBar.aegisTrackTopo,juggBar.aegisFillTopo]) RuiTopology_Destroy(topo)
    })
    juggBar.lastDraw = Time()
    while (true)
    {
        JuggBarDraw()
        WaitFrame()
    }
}

string function JuggBossName()
{
    array<string> names
    foreach (entity p in GetPlayerArray())
        if (IsValid(p) && p.GetTeam() == TEAM_IMC && IsAlive(p) && p.IsTitan()) names.append(p.GetPlayerName())
    if (names.len() >= 2) return "TWIN JUGGERNAUTS"
    return names.len() == 1 ? names[0].toupper() : "JUGGERNAUT"
}

void function JuggBarShow(var rui,bool shown,float alpha)
{
    RuiSetFloat(rui,"basicImageAlpha",shown ? alpha : 0.0)
}

void function JuggBarDraw()
{
    entity player = GetLocalClientPlayer()
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height/1080.0
    float dt = clamp(Time()-juggBar.lastDraw,0.0,0.25)
    juggBar.lastDraw = Time()
    bool live = IsValid(player) && GetGameState() == eGameState.Playing && GetGlobalNetInt("juggPhase") == 2 && JuggGetHealthNet("juggHullMax") > 0
    bool boss = live && player.GetPlayerNetBool("juggIsBoss")
    bool showHull = live && !boss
    float w = 460.0*s
    float x = width*0.5-w*0.5
    float y = height*0.172
    float barY = y+24.0*s
    JuggBarDrawHull(live,showHull,x,y,barY,w,s,dt)

    JuggBarDrawAegis(live,x,boss ? y-6.0*s : barY+11.0*s,w,s)
    JuggBarDrawFlyouts(showHull,x,barY,w,s)
}

void function JuggBarDrawHull(bool live,bool showHull,float x,float y,float barY,float w,float s,float dt)
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    int hp = JuggGetHealthNet("juggHull")
    int maximum = JuggGetHealthNet("juggHullMax")
    int shield = JuggGetHealthNet("juggShield")

    float frac = live ? clamp(hp.tofloat()/maxint(1,maximum),0.0,1.0) : 1.0
    if (!live) juggBar.trailFrac = 1.0
    if (frac < juggBar.hullFrac-0.0001) juggBar.trailHoldUntil = Time()+0.4
    juggBar.hullFrac = frac
    if (frac >= juggBar.trailFrac) juggBar.trailFrac = frac
    else if (Time() > juggBar.trailHoldUntil) juggBar.trailFrac = max(frac,juggBar.trailFrac-0.7*dt)
    bool doomed = juggHUDDoomed && juggHUDMetadataRound == GetGlobalNetInt("juggRound")
    vector color = frac < 0.25 ? <1.0,0.3,0.2> : <1.0,0.62,0.28>
    if (doomed) color = int(Time()*4)%2 == 0 ? <1.0,0.18,0.1> : <0.5,0.06,0.03>
    float shieldFrac = juggHUDShieldMax > 0 ? clamp(shield.tofloat()/juggHUDShieldMax,0.0,1.0) : 0.0
    JuggHudPlace(juggBar.shieldTopo,x,barY-4.0*s,max(0.5,w*shieldFrac),2.0*s)
    JuggHudPlace(juggBar.trackTopo,x,barY,w,6.0*s)
    JuggHudPlace(juggBar.trailTopo,x,barY,max(0.5,w*juggBar.trailFrac),6.0*s)
    JuggHudPlace(juggBar.hullTopo,x,barY,max(0.5,w*frac),6.0*s)
    RuiSetFloat3(juggBar.hull,"basicImageColor",color)
    JuggBarShow(juggBar.track,showHull,0.6)
    JuggBarShow(juggBar.shield,showHull && shieldFrac > 0.0,0.95)
    JuggBarShow(juggBar.trail,showHull && juggBar.trailFrac > frac+0.001,0.55)
    JuggBarShow(juggBar.hull,showHull,1.0)
    RuiSetString(juggBar.name,"msgText",doomed ? JuggBossName() + "   DOOMED" : JuggBossName())
    RuiSetFloat3(juggBar.name,"msgColor",doomed ? <1.0,0.35,0.25> : <0.92,0.93,0.95>)
    RuiSetFloat2(juggBar.name,"msgPos",<x/width,y/height,0>)
    RuiSetFloat(juggBar.name,"msgAlpha",showHull ? 0.9 : 0.0)
    RuiSetString(juggBar.percent,"msgText",int(ceil(frac*100.0)) + "%")
    RuiSetFloat2(juggBar.percent,"msgPos",<(x+w-16.0*s)/width-0.5,(y+8.0*s)/height-0.5,0>)
    RuiSetFloat(juggBar.percent,"msgAlpha",showHull ? 0.9 : 0.0)
}

void function JuggBarDrawAegis(bool live,float x,float aY,float w,float s)
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    int tier = minint(3,maxint(0,GetGlobalNetInt("juggAegisTier")))
    int perTier = maxint(1,GetGlobalNetInt("juggAegisPerTier"))
    int kills = tier >= 3 ? 0 : minint(perTier-1,maxint(0,GetGlobalNetInt("juggAegisKills")))
    if (tier > juggBar.shownTier) juggBar.tierFlashUntil = Time()+0.8
    juggBar.shownTier = tier
    float aegisFrac = (tier+kills.tofloat()/perTier)/3.0
    JuggHudPlace(juggBar.aegisTrackTopo,x,aY,w,2.0*s)
    JuggHudPlace(juggBar.aegisFillTopo,x,aY,max(0.5,w*aegisFrac),2.0*s)
    bool flash = Time() < juggBar.tierFlashUntil && int(Time()*10)%2 == 0
    RuiSetFloat3(juggBar.aegisFill,"basicImageColor",flash ? <1,1,1> : <1.0,0.72,0.3>)
    JuggBarShow(juggBar.aegisTrack,live,0.5)
    JuggBarShow(juggBar.aegisFill,live && aegisFrac > 0.0,1.0)
    string aegis = "AEGIS " + tier + "/3"
    if (tier >= 3) aegis += "    MAX"
    else aegis += "    " + (perTier-kills) + ((perTier-kills) == 1 ? " KILL" : " KILLS") + " TO NEXT"
    RuiSetString(juggBar.aegisText,"msgText",aegis)
    RuiSetFloat2(juggBar.aegisText,"msgPos",<x/width,(aY+5.0*s)/height,0>)
    RuiSetFloat(juggBar.aegisText,"msgAlpha",live ? 0.8 : 0.0)
}

void function JuggBarDrawFlyouts(bool showHull,float x,float barY,float w,float s)
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    foreach (JuggFlyout flyout in juggBar.flyouts)
    {
        float age = Time()-flyout.born
        bool shown = showHull && age >= 0.0 && age < 0.85
        if (shown)
        {
            float t = min(1.0,age/0.7)
            float rise = 1.0-(1.0-t)*(1.0-t)
            float fx = x+min(w*flyout.x,w-24.0*s)+flyout.drift*40.0*s*rise
            float fy = barY-6.0*s-34.0*s*rise
            RuiSetString(flyout.rui,"msgText",JuggComma(flyout.amount))
            RuiSetFloat(flyout.rui,"msgFontSize",flyout.amount >= 1000 ? 22.0 : 17.0)
            RuiSetFloat3(flyout.rui,"msgColor",flyout.amount >= 1000 ? <1.0,0.72,0.3> : <1,1,1>)
            RuiSetFloat2(flyout.rui,"msgPos",<fx/width-0.5,fy/height-0.5,0>)
        }
        RuiSetFloat(flyout.rui,"msgAlpha",shown ? (age < 0.5 ? 0.95 : 0.95*(0.85-age)/0.35) : 0.0)
    }
}

void function JuggCoreIconThink()
{
    string last = ""
    while (true)
    {
        entity player = GetLocalViewPlayer()
        string key = ""
        if (IsValid(player) && IsAlive(player) && player.IsTitan())
        {
            entity core = player.GetOffhandWeapon(OFFHAND_EQUIPMENT)
            entity soul = player.GetTitanSoul()
            key = (IsValid(core) ? core.GetWeaponClassName() + ":" + core.GetMods().len() : "none")
            key += "/" + PlayerEarnMeter_GetMode(player) + "/" + (IsValid(soul) ? soul.GetTitanSoulNetInt("upgradeCount") : -1)
        }
        if (key != last)
        {
            last = key
            if (key != "") EarnMeter_Update()
        }
        wait 0.25
    }
}

void function JuggSpecialFXThink()
{
    int shownRound = -1
    while (true)
    {
        wait 0.1
        entity player = GetLocalClientPlayer()
        int round = GetGlobalNetInt("juggRound")
        if (!IsValid(player) || GetGlobalNetInt("juggPhase") != 2 || round == shownRound) continue
        shownRound = round
        if (GetGlobalNetInt("juggSpecial") > 0) thread JuggCockpitBurst($"P_MFD",2.5,"UI_InGame_MarkedForDeath_PlayerMarked")
    }
}

void function JuggCockpitBurst(asset effect,float life,string sound)
{
    entity player = GetLocalClientPlayer()
    if (!IsValid(player)) return
    float deadline = Time()+2.0
    while (!IsValid(player.GetCockpit()) && Time() < deadline) WaitFrame()
    entity cockpit = player.GetCockpit()
    if (!IsValid(cockpit)) return
    if (sound != "") EmitSoundOnEntity(player,sound)
    int fx = StartParticleEffectOnEntity(cockpit,GetParticleSystemIndex(effect),FX_PATTACH_ABSORIGIN_FOLLOW,-1)
    wait life
    if (IsValid(cockpit) && EffectDoesExist(fx)) EffectStop(fx,true,false)
}
