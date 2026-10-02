untyped
global function PH_ClientInit
global function PH_Feedback
const int PH_SLOTS = 5

struct
{
    string toast = ""
    vector toastColor = <1,1,1>
    float toastAt = -99.0
    int flashSlot = -1
    float flashAt = -99.0
    bool flashDeny = false
} phHud
void function PH_ClientInit()
{
    ClGameState_RegisterGameStateAsset( $"ui/gamestate_info_lts.rpak" )
    AddCallback_IsValidMeleeExecutionTarget( PH_CanExecute )
    array<int> buttons=PH_KeyCodes()
    buttons.extend(PH_PadCodes())
    foreach(int button in buttons)
    {
        if(button<0) continue
        RegisterButtonPressedCallback(button,void function(entity p) : (button) { PH_Input(button) })
    }
    PH_AnnouncementsInit()
    PH_ArenaVisualInit()
    thread PH_HUD()
    thread PH_Visuals()
    thread PH_HunterHealthAudio()
}
void function PH_Send( string command )
{
    entity p = GetLocalClientPlayer()
    if ( !IsValid( p ) || !IsAlive( p ) || !p.GetPlayerNetBool( "phDisguised" ) ) return
    p.ClientCommand( command )
}
void function PH_PressReroll( entity player ) { PH_Send( "ph_reroll" ) }
void function PH_PressDecoy( entity player ) { PH_Send( "ph_decoy" ) }
void function PH_PressLock( entity player ) { PH_Send( "ph_lock" ) }
void function PH_PressFreeze( entity player ) { PH_Send( "ph_freeze" ) }

void function PH_Feedback( int kind, int value )
{
    entity p = GetLocalClientPlayer()
    if ( !IsValid( p ) ) return
    vector teal = <0.35,1.0,0.8>
    vector amber = <1.0,0.78,0.30>
    string text = ""
    vector color = teal
    string sound = ""
    int slot = -1
    if ( kind == PH_FB_DENY )
    {
        phHud.flashDeny = true
        phHud.flashAt = Time()
        EmitSoundOnEntity( p, "coop_sentrygun_deploymentdeniedbeep" )
        return
    }
    if ( kind == PH_FB_REROLL )
    {
        array<string> names = PH_MapNames()
        text = "NEW DISGUISE: " + (value >= 0 && value < names.len() ? names[value].toupper() : "?")
        sound = "UI_InGame_FD_ArmorySymbolAppear"
        slot = 0
    }
    else if ( kind == PH_FB_DECOY )
    {
        text = GetGlobalNetBool( "phDebug" ) ? "DECOY PLACED" : format( "DECOY PLACED  -  %d LEFT", value )
        sound = "holopilot_deploy_1p"
        slot = 1
    }
    else if ( kind == PH_FB_LOCK )
    {
        text = value == 1 ? "ROTATION LOCKED" : "ROTATION FREE"
        sound = "UI_InGame_FD_WaveTick"
        slot = 2
    }
    else if ( kind == PH_FB_FREEZE )
    {
        text = value == 1 ? "FROZEN  -  YOU ARE PART OF THE MAP" : "UNFROZEN  -  YOU CAN MOVE"
        sound = value == 1 ? "UI_InGame_FD_ReadyUp_1p" : "UI_InGame_FD_UnReadyUp_1p"
        slot = 3
    }
    else if ( kind == PH_FB_TAUNT ) { text = "TAUNT!  THE HUNTERS HEARD YOU"; color = amber; slot = 4; }
    else if ( kind == PH_FB_CUE ) { text = "YOU MADE A SOUND"; color = amber; }
    else if ( kind == PH_FB_DECOY_BROKEN ) { text = "A HUNTER SHOT YOUR DECOY"; color = amber; sound = "HUD_MP_EnemySonarTag_Flashed_1P"; }
    else if ( kind == PH_FB_MISS ) { text = format( "MISSED  -  %d SECONDS OFF THE CLOCK", value ); color = amber; sound = "coop_sentrygun_deploymentdeniedbeep"; }
    else return
    phHud.toast = text
    phHud.toastColor = color
    phHud.toastAt = Time()
    if ( slot >= 0 ) { phHud.flashSlot = slot; phHud.flashAt = Time(); phHud.flashDeny = false; }
    if ( sound != "" ) EmitSoundOnEntity( p, sound )
}

var function PH_HudText( asset kind, float size, vector color, int sort )
{
    var rui = CreateFullscreenRui( kind, sort )
    RuiSetInt( rui, "maxLines", 3 )
    RuiSetInt( rui, "lineNum", 0 )
    RuiSetFloat( rui, "msgFontSize", size )
    RuiSetFloat( rui, "msgAlpha", 0.0 )
    RuiSetFloat( rui, "thicken", 0.0 )
    RuiSetFloat3( rui, "msgColor", color )
    return rui
}

var function PH_HudRect( var topo, vector color, float alpha, int sort )
{
    var rui = RuiCreate( $"ui/basic_image.rpak", topo, RUI_DRAW_HUD, sort )
    RuiSetFloat3( rui, "basicImageColor", color )
    RuiSetFloat( rui, "basicImageAlpha", alpha )
    return rui
}
void function PH_Place( var topo, float x, float y, float w, float h )
{
    RuiTopology_UpdatePos( topo, <x,y,0>, <w,0,0>, <0,h,0> )
}
void function PH_TextAt( var rui, string text, float x, float y, float alpha, float width, float height )
{
    RuiSetString( rui, "msgText", text )
    RuiSetFloat2( rui, "msgPos", <x/width,y/height,0> )
    RuiSetFloat( rui, "msgAlpha", alpha )
}

struct
{
    var waitTopo
    var waitBack
    var waitText
    var waitText2
    var waitText3
    bool waitVideo = false
    var statusTopo
    var statusBack
    var statusAccentTopo
    var statusAccent
    var statusTitle
    var statusDetail
    var propTopo
    var propBack
    var nameText
    var hpText
    var hpTopo
    var hpBack
    var hpFillTopo
    var hpFill
    array<var> slotTopos
    array<var> slotBacks
    array<var> slotFlashes
    array<var> slotKeys
    array<var> slotNames
    array<var> slotValues
    var tauntTopo
    var tauntFill
    var toastText
    var watermark
} phUi
vector function PH_Teal() { return <0.35,1.0,0.8> }
vector function PH_Amber() { return <1.0,0.78,0.30> }
vector function PH_Muted() { return <0.62,0.68,0.74> }
vector function PH_Red() { return <1.0,0.40,0.35> }
var function PH_NewTopo() { return RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false ) }

void function PH_HudCreate()
{
    asset LEFT = $"ui/cockpit_console_text_top_left.rpak"
    asset CENTER = $"ui/cockpit_console_text_center.rpak"

    phUi.waitTopo = PH_NewTopo()

    phUi.waitBack = PH_HudRect( phUi.waitTopo, <0.0024,0.0024,0.0024>, 0.0, 105 )
    phUi.waitText = PH_HudText( CENTER, 38.0, <1,1,1>, 121 )
    phUi.waitText2 = PH_HudText( CENTER, 38.0, <1,1,1>, 121 )
    phUi.waitText3 = PH_HudText( CENTER, 38.0, <1,1,1>, 121 )

    phUi.statusTopo = PH_NewTopo()
    phUi.statusBack = PH_HudRect( phUi.statusTopo, <0.015,0.025,0.035>, 0.0, 109 )
    phUi.statusAccentTopo = PH_NewTopo()
    phUi.statusAccent = PH_HudRect( phUi.statusAccentTopo, PH_Teal(), 0.0, 110 )
    phUi.statusTitle = PH_HudText( LEFT, 30.0, <1,1,1>, 111 )
    phUi.statusDetail = PH_HudText( LEFT, 19.0, PH_Muted(), 111 )

    phUi.propTopo = PH_NewTopo()
    phUi.propBack = PH_HudRect( phUi.propTopo, <0.01,0.015,0.02>, 0.0, 108 )
    phUi.nameText = PH_HudText( LEFT, 26.0, <1,1,1>, 111 )
    phUi.hpText = PH_HudText( LEFT, 18.0, PH_Muted(), 111 )
    phUi.hpTopo = PH_NewTopo()
    phUi.hpBack = PH_HudRect( phUi.hpTopo, <0.04,0.05,0.07>, 0.0, 109 )
    phUi.hpFillTopo = PH_NewTopo()
    phUi.hpFill = PH_HudRect( phUi.hpFillTopo, PH_Teal(), 0.0, 110 )
    for ( int i = 0; i < PH_SLOTS; i++ )
    {
        var topo = PH_NewTopo()
        phUi.slotTopos.append( topo )
        phUi.slotBacks.append( PH_HudRect( topo, <0.04,0.05,0.07>, 0.0, 109 ) )
        phUi.slotFlashes.append( PH_HudRect( topo, <1,1,1>, 0.0, 110 ) )
        phUi.slotKeys.append( PH_HudText( LEFT, 16.0, PH_Teal(), 111 ) )
        phUi.slotNames.append( PH_HudText( LEFT, 21.0, <1,1,1>, 111 ) )
        phUi.slotValues.append( PH_HudText( LEFT, 16.0, PH_Muted(), 111 ) )
    }
    phUi.tauntTopo = PH_NewTopo()
    phUi.tauntFill = PH_HudRect( phUi.tauntTopo, PH_Amber(), 0.0, 111 )
    phUi.toastText = PH_HudText( CENTER, 30.0, <1,1,1>, 125 )
    RuiSetFloat( phUi.toastText, "thicken", 0.2 )
    RuiSetFloat2( phUi.toastText, "msgPos", <0,0.12,0> )
    phUi.watermark = PH_HudText( CENTER, 22.0, <1,1,1>, 120 )
    RuiSetInt( phUi.watermark, "maxLines", 2 )
    RuiSetFloat( phUi.watermark, "msgAlpha", 0.45 )
    RuiSetFloat2( phUi.watermark, "msgPos", <0.40,0.40,0> )
    RuiSetString( phUi.watermark, "msgText", "property of ceaika,\ndo not redistribute" )
}

void function PH_HudDestroy()
{
    if ( IsValid( GetLocalClientPlayer() ) ) GetLocalClientPlayer().UnhideCrosshairNames()
    if ( IsValid( GetLocalClientPlayer() ) ) PH_WaitVideo( GetLocalClientPlayer(), false )
    array ruis =[phUi.waitBack, phUi.waitText, phUi.waitText2, phUi.waitText3, phUi.statusBack, phUi.statusAccent, phUi.statusTitle, phUi.statusDetail,
        phUi.propBack, phUi.nameText, phUi.hpText, phUi.hpBack, phUi.hpFill, phUi.tauntFill, phUi.toastText, phUi.watermark]
    ruis.extend( phUi.slotBacks )
    ruis.extend( phUi.slotFlashes )
    ruis.extend( phUi.slotKeys )
    ruis.extend( phUi.slotNames )
    ruis.extend( phUi.slotValues )
    foreach ( rui in ruis ) RuiDestroyIfAlive( rui )
    array topos = [phUi.propTopo, phUi.waitTopo, phUi.statusTopo, phUi.statusAccentTopo, phUi.hpTopo, phUi.hpFillTopo, phUi.tauntTopo]
    topos.extend( phUi.slotTopos )
    foreach ( topo in topos ) RuiTopology_Destroy( topo )
}

void function PH_HUD()
{
    while ( !IsValid( GetLocalClientPlayer() ) ) WaitFrame()
    GetLocalClientPlayer().HideCrosshairNames()
    PH_HudCreate()
    OnThreadEnd( function() { PH_HudDestroy() } )
    while ( true )
    {
        entity p = GetLocalClientPlayer()
        if ( !IsValid( p ) ) { wait 0.1; continue; }
        PH_HudWait( p )
        PH_HudStatus( p )
        PH_HudProp( p )
        PH_HudToast()
        WaitFrame()
    }
}

void function PH_HudWait( entity p )
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    int remaining = maxint( 0, int( ceil( GetGlobalNetTime( "phEnd" )-Time() ) ) )
    bool waiting = GetGlobalNetInt( "phPhase" ) == 1 && IsAlive( p ) && !p.GetPlayerNetBool( "phDisguised" )
    PH_Place( phUi.waitTopo, 0, 0, width, height )
    RuiSetFloat( phUi.waitBack, "basicImageAlpha", waiting ? 1.0 : 0.0 )
    foreach ( rui in [phUi.waitText, phUi.waitText2, phUi.waitText3] ) RuiSetFloat( rui, "msgAlpha", waiting ? 1.0 : 0.0 )
    RuiSetString( phUi.waitText, "msgText", "YOU ARE A HUNTER" )
    RuiSetString( phUi.waitText2, "msgText", "WAITING FOR PROPS TO HIDE" )
    RuiSetString( phUi.waitText3, "msgText", format( "HUNT STARTS IN %d SECONDS", remaining ) )

    float video = PH_WaitVideoHeight()/height
    RuiSetFloat2( phUi.waitText, "msgPos", <0,0.135*video-0.5,0> )
    RuiSetFloat2( phUi.waitText2, "msgPos", <0,0.191*video-0.5,0> )
    RuiSetFloat2( phUi.waitText3, "msgPos", <0,video+0.045-0.5,0> )
    PH_WaitVideo( p, waiting )
}

void function PH_WaitVideo( entity p, bool waiting )
{
    if ( waiting == phUi.waitVideo ) return
    phUi.waitVideo = waiting
    if ( !waiting ) { p.ClientCommand( "stopvideos" ); return; }
    p.ClientCommand( format( "playvideo_nointerrupt ceaika_ph_wait %d %d", int( GetScreenSize()[0] ), int( PH_WaitVideoHeight() ) ) )
}

float function PH_WaitVideoHeight()
{
    return min( GetScreenSize()[0]*0.5, GetScreenSize()[1]*0.9 )
}

void function PH_HudStatus( entity p )
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    int phase = GetGlobalNetInt( "phPhase" )
    int remaining = maxint( 0, int( ceil( GetGlobalNetTime( "phEnd" )-Time() ) ) )
    string clock = GetGlobalNetTime( "phEnd" ) <= 0.0 ? "--:--" : format( "%d:%02d", remaining/60, remaining%60 )
    bool prop = p.GetPlayerNetBool( "phDisguised" ) && IsAlive( p )
    string title = "PROP HUNT"
    string detail = "Waiting for at least two players"
    vector accent = PH_Teal()
    if ( phase == 4 ) detail = "This map isn't set up for Prop Hunt"
    else if ( phase == 1 ) { title = "HIDE  " + clock; detail = format( "Round %d  -  hunters are released soon", GetGlobalNetInt( "phRound" ) ); }
    else if ( phase == 2 )
    {
        int alive = GetGlobalNetInt( "phAlive" )
        title = "HUNT  " + clock
        accent = PH_Amber()
        detail = format( "Round %d  -  %d prop%s left", GetGlobalNetInt( "phRound" ), alive, alive == 1 ? "" : "s" )
    }
    else if ( phase == 3 )
    {
        int winner = GetGlobalNetInt( "phWinner" )
        title = winner == 0 ? "ROUND RESET" : (winner == GetGlobalNetInt( "phPropTeam" ) ? "PROPS WIN" : "HUNTERS WIN")
        detail = "Teams swap roles in " + remaining + " s"
    }
    bool playing = phase == 1 || phase == 2
    if ( playing && !IsAlive( p ) ) detail = "Eliminated  -  you return next round"
    else if ( playing && !prop ) detail += "\nHunter  -  follow the sounds"
    if ( playing && IsAlive( p ) && PH_ArenaNearEdge( p.GetOrigin() ) ) { detail = "PLAY AREA EDGE  -  TURN BACK"; accent = PH_Red(); }
    if ( GetGlobalNetBool( "phDebug" ) ) title += "  DEBUG"
    float x = width*0.025
    float y = height*0.29
    float h = (detail.find( "\n" ) != null ? 92.0 : 70.0)*s
    PH_Place( phUi.statusTopo, x, y, 380.0*s, h )
    PH_Place( phUi.statusAccentTopo, x, y, 4.0*s, h )
    RuiSetFloat( phUi.statusBack, "basicImageAlpha", 0.72 )
    RuiSetFloat3( phUi.statusAccent, "basicImageColor", accent )
    RuiSetFloat( phUi.statusAccent, "basicImageAlpha", 1.0 )
    RuiSetFloat3( phUi.statusTitle, "msgColor", accent )
    PH_TextAt( phUi.statusTitle, title, x+16.0*s, y+8.0*s, 1.0, width, height )
    RuiSetFloat3( phUi.statusDetail, "msgColor", accent == PH_Red() ? PH_Red() : PH_Muted() )
    PH_TextAt( phUi.statusDetail, detail, x+16.0*s, y+42.0*s, 1.0, width, height )
}

void function PH_HudProp( entity p )
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    int phase = GetGlobalNetInt( "phPhase" )
    bool prop = p.GetPlayerNetBool( "phDisguised" ) && IsAlive( p ) && (phase == 1 || phase == 2)
    float total = PH_SLOTS*150.0*s + (PH_SLOTS-1)*8.0*s
    float x0 = width*0.5 - total*0.5
    float y0 = height - 190.0*s
    if ( prop )
    {
        array<string> names = PH_MapNames()
        int index = minint( names.len()-1, maxint( 0, PH_ModelIndex( p ) ) )
        float frac = clamp( float( p.GetHealth() ) / float( maxint( 1, p.GetMaxHealth() ) ), 0.0, 1.0 )
        PH_TextAt( phUi.nameText, names[index], x0, y0-66.0*s, 1.0, width, height )
        PH_TextAt( phUi.hpText, string( p.GetHealth() ) + " / " + string( p.GetMaxHealth() ) + " HP", x0+total-112.0*s, y0-60.0*s, 1.0, width, height )
        PH_Place( phUi.hpTopo, x0, y0-24.0*s, total, 8.0*s )
        PH_Place( phUi.hpFillTopo, x0, y0-24.0*s, max( 1.0, total*frac ), 8.0*s )
        RuiSetFloat3( phUi.hpFill, "basicImageColor", frac > 0.5 ? PH_Teal() : (frac > 0.25 ? PH_Amber() : PH_Red()) )
    }
    else
    {
        RuiSetFloat( phUi.nameText, "msgAlpha", 0.0 )
        RuiSetFloat( phUi.hpText, "msgAlpha", 0.0 )
    }

    PH_Place( phUi.propTopo, x0-12.0*s, y0-78.0*s, total+24.0*s, 160.0*s )
    RuiSetFloat( phUi.propBack, "basicImageAlpha", prop ? 0.55 : 0.0 )
    RuiSetFloat( phUi.hpBack, "basicImageAlpha", prop ? 0.8 : 0.0 )
    RuiSetFloat( phUi.hpFill, "basicImageAlpha", prop ? 1.0 : 0.0 )
    for ( int i = 0; i < PH_SLOTS; i++ ) PH_HudSlot( p, i, prop, x0 + i*158.0*s, y0 )
}

void function PH_HudSlot( entity p, int i, bool prop, float x, float y )
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    float w = 150.0*s
    float h = 70.0*s
    int phase = GetGlobalNetInt( "phPhase" )
    bool debug = GetGlobalNetBool( "phDebug" )
    bool frozen = p.GetPlayerNetBool( "phFrozen" )
    array<string> actions = ["reroll","decoy","lock","freeze","taunt"]
    array<string> labels = ["REROLL","DECOY","LOCK","FREEZE","TAUNT"]
    string value = ""
    bool active = false
    bool usable = true
    float tauntLeft = max( 0.0, p.GetPlayerNetTime( "phTauntReady" ) - Time() )

    bool tauntOpen = phase == 2 || (phase == 1 && (GetGlobalNetBool( "phDebug" ) || GetGlobalNetTime( "phEnd" ) <= 0.0))
    if ( i == 0 ) { int left = PH_RerollsLeft( p ); value = debug ? "unlimited" : string( left ) + " left"; usable = debug || left > 0; }
    else if ( i == 1 ) { int left = PH_DecoysLeft( p ); value = debug ? "unlimited" : string( left ) + " left"; usable = debug || left > 0; }
    else if ( i == 2 ) { active = p.GetPlayerNetBool( "phLocked" ); value = active ? "LOCKED" : "free"; }
    else if ( i == 3 ) { active = frozen; value = frozen ? "FROZEN" : "move"; }
    else
    {
        usable = tauntOpen && tauntLeft <= 0.0
        value = !tauntOpen ? "in hunt" : (tauntLeft > 0.0 ? format( "%d s", int( ceil( tauntLeft ) ) ) : "READY")
    }
    if ( (i == 0 || i == 2) && frozen ) usable = false
    PH_Place( phUi.slotTopos[i], x, y, w, h )
    RuiSetFloat3( phUi.slotBacks[i], "basicImageColor", active ? <0.04,0.28,0.22> : <0.04,0.05,0.07> )
    RuiSetFloat( phUi.slotBacks[i], "basicImageAlpha", prop ? 0.8 : 0.0 )
    float since = Time() - phHud.flashAt
    bool flashing = prop && since < 0.35 && (phHud.flashSlot == i || phHud.flashDeny)
    RuiSetFloat3( phUi.slotFlashes[i], "basicImageColor", phHud.flashDeny ? PH_Red() : <1,1,1> )
    RuiSetFloat( phUi.slotFlashes[i], "basicImageAlpha", flashing ? (phHud.flashDeny ? 0.3 : 0.45)*(1.0-since/0.35) : 0.0 )
    float alpha = prop ? (usable || active ? 1.0 : 0.4) : 0.0
    RuiSetFloat3( phUi.slotKeys[i], "msgColor", i == 4 ? PH_Amber() : PH_Teal() )
    PH_TextAt( phUi.slotKeys[i], PH_KeyLabels()[PH_BindingIndex( actions[i], false )], x+12.0*s, y+6.0*s, alpha, width, height )
    PH_TextAt( phUi.slotNames[i], labels[i], x+12.0*s, y+24.0*s, alpha, width, height )
    RuiSetFloat3( phUi.slotValues[i], "msgColor", active ? PH_Teal() : PH_Muted() )
    PH_TextAt( phUi.slotValues[i], value, x+12.0*s, y+47.0*s, alpha, width, height )
    if ( i == 4 )
    {

        float length = phase == 1 || GetGlobalNetBool( "phDebug" ) ? 1.0 : float( maxint( 3, GetCurrentPlaylistVarInt( "ph_taunt_cooldown", 10 ) ) )
        float done = tauntOpen ? 1.0 - clamp( tauntLeft/length, 0.0, 1.0 ) : 0.0
        PH_Place( phUi.tauntTopo, x, y+h-4.0*s, max( 1.0, w*done ), 4.0*s )
        RuiSetFloat( phUi.tauntFill, "basicImageAlpha", prop && tauntOpen ? 1.0 : 0.0 )
    }
}

void function PH_HudToast()
{
    float age = Time() - phHud.toastAt
    RuiSetString( phUi.toastText, "msgText", phHud.toast )
    RuiSetFloat3( phUi.toastText, "msgColor", phHud.toastColor )
    RuiSetFloat( phUi.toastText, "msgAlpha", age < 1.2 ? 1.0 : clamp( 1.0-(age-1.2)/0.4, 0.0, 1.0 ) )
}

void function PH_Visuals()
{
    table<entity,entity> visuals
    table<entity,entity> proxies
    table<entity,array<entity> > pieces
    OnThreadEnd( function() : (visuals,pieces) {
        foreach ( entity visual in visuals ) if ( IsValid( visual ) ) visual.Destroy()
        foreach ( entity p, array<entity> list in pieces ) PH_DestroyPieces( list )
    } )
    while ( true )
    {
        array<entity> active
        foreach ( entity p in GetPlayerArray() )
        {
            if ( !IsValid( p ) || !IsAlive( p ) ) continue
            entity body = p.GetPlayerNetEnt( "phBody" )
            if ( !IsValid( body ) ) continue
            active.append( p )
            if ( !(p in visuals) || !IsValid( visuals[p] ) || proxies[p] != body )
            {
                if ( p in visuals && IsValid( visuals[p] ) ) visuals[p].Destroy()
                if ( p in pieces ) PH_DestroyPieces( pieces[p] )
                visuals[p] <- CreateClientSidePropDynamic( p.GetOrigin(), body.GetAngles(), body.GetModelName() )
                pieces[p] <- PH_CreatePieces( body.GetModelName() )
                proxies[p] <- body
            }
            entity visual = visuals[p]
            vector angles = body.GetAngles()
            if ( p == GetLocalClientPlayer() && !p.GetPlayerNetBool( "phLocked" ) && !p.GetPlayerNetBool("phFrozen") ) angles = <0,p.EyeAngles().y,0>
            visual.SetAngles( angles )
            visual.SetOrigin( p.GetPlayerNetBool("phFrozen") ? body.GetOrigin() : PH_ModelOrigin( body, p.GetOrigin(), angles ) )
            PH_PlacePieces( pieces[p], body.GetModelName(), visual.GetOrigin(), angles )
        }
        array<entity> stale
        foreach ( entity p, entity visual in visuals ) if ( !active.contains( p ) ) stale.append( p )
        foreach ( entity p in stale )
        {
            if ( IsValid( visuals[p] ) ) visuals[p].Destroy()
            if ( p in pieces ) { PH_DestroyPieces( pieces[p] ); delete pieces[p]; }
            delete visuals[p]
            delete proxies[p]
        }
        WaitFrame()
    }
}

void function PH_Input(int button)
{
    array<string> actions=["reroll","decoy","lock","freeze","taunt"]
    foreach(string action in actions)
    {
        if(PH_KeyCodes()[PH_BindingIndex(action,false)]==button || PH_PadCodes()[PH_BindingIndex(action,true)]==button)
        { PH_Send("ph_"+action); return; }
    }
}

void function PH_HunterHealthAudio()
{
    array<string> loops = ["pilot_wounded_loop_1p", "pilot_critical_breath_loop_1p", "pilot_critical_drone_loop_1p"]
    while(true)
    {
        entity p=GetLocalViewPlayer()
        if(!IsValid(p)) { wait 0.1; continue; }
        int phase=GetGlobalNetInt("phPhase")
        if(IsValid(p) && IsAlive(p) && (phase==1 || phase==2) && p.GetTeam()!=GetGlobalNetInt("phPropTeam"))
        {
            entity cockpit=p.GetCockpit()
            foreach(string sound in loops)
            {
                StopSoundOnEntity(p,sound)
                if(IsValid(cockpit)) StopSoundOnEntity(cockpit,sound)
            }
        }
        wait 0.1
    }
}

array<entity> function PH_CreatePieces( asset owner )
{
    array<entity> list
    array<PHPart> parts = PH_MapParts()
    for ( int i = 0; i < parts.len(); i++ )
    {
        if ( parts[i].owner != owner ) continue
        entity piece = CreateClientSidePropDynamic( <0,0,0>, <0,0,0>, parts[i].model )
        if ( parts[i].scale != 1.0 )
        {
            try { piece.kv.modelscale = parts[i].scale }
            catch ( error ) {}
        }
        list.append( piece )
    }
    return list
}
void function PH_PlacePieces( array<entity> list, asset owner, vector origin, vector angles )
{
    array<PHPart> parts = PH_MapParts()
    int n = 0
    for ( int i = 0; i < parts.len() && n < list.len(); i++ )
    {
        if ( parts[i].owner != owner ) continue
        if ( IsValid( list[n] ) )
        {
            list[n].SetOrigin( PH_PartOrigin( origin, angles, parts[i].offset ) )
            list[n].SetAngles( PH_PartAngles( angles, parts[i].angles ) )
        }
        n++
    }
}
void function PH_DestroyPieces( array<entity> list )
{
    foreach ( entity piece in list ) if ( IsValid( piece ) ) piece.Destroy()
    list.clear()
}
