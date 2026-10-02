untyped
global function Cl_HotPotato_Init
global function HP_Feedback

struct
{
    var incoming = null
    var destination = null
    var carrierMarker = null
    int markedFX = -1
    entity cockpit = null
} file

struct
{
    var fuse = null
    var panelTopo = null
    var panelBack = null
    var accentTopo = null
    var accent = null
    var title = null
    var detail = null
    var barTopo = null
    var barBack = null
    var fillTopo = null
    var fill = null
    int lastBeep = -1
} hpUi

void function Cl_HotPotato_Init()
{
    ClGameState_RegisterGameStateAsset( $"ui/gamestate_info_ffa.rpak" )
    AddCallback_IsValidMeleeExecutionTarget( HP_CanExecute )
    thread HP_Presentation()
}

void function HP_Feedback( int event, int reward )
{
    entity player = GetLocalClientPlayer()
    if ( !IsValid( player ) ) return
    vector blue = <0.35,0.8,1.0>
    if ( event == 0 )
    {
        EmitSoundOnEntity( player, "UI_InGame_MarkedForDeath_PlayerMarked" )
        PartyUI_Banner( "YOU HAVE THE POTATO", "Melee another pilot before it explodes. You're faster and can see everyone.", <1.0,0.3,0.1>, 3.5 )
    }
    else if ( event == 1 )
    {

        EmitSoundOnEntity( player, "UI_TitanBattery_Pilot_Give_TitanBattery" )
    }
    else if ( event == 2 ) PartyUI_Feed( "SUPPLY DROP INCOMING | Follow the landing marker. One hack per pilot this round.", blue )
    else if ( event == 3 ) PartyUI_Feed( "TERMINAL READY | Hack it for 3 seconds to claim a random tactical", blue )
    else if ( event == 4 )
    {
        array<string> names = ["PHASE SHIFT", "STIM", "GRAPPLE", "HOLOPILOT"]
        EmitSoundOnEntity( player, "UI_TitanBattery_Pilot_Give_TitanBattery" )
        PartyUI_Banner( names[minint( 3, maxint( 0, reward ) )] + " ACQUIRED", "Press your tactical button. One use this round.", blue, 3.0 )
    }
}

var function HP_Text( float size, vector color )
{
    var rui = CreateFullscreenRui( $"ui/cockpit_console_text_top_left.rpak", 111 )
    RuiSetInt( rui, "maxLines", 4 )
    RuiSetInt( rui, "lineNum", 0 )
    RuiSetFloat( rui, "msgFontSize", size )
    RuiSetFloat( rui, "msgAlpha", 0.0 )
    RuiSetFloat( rui, "thicken", 0.0 )
    RuiSetFloat3( rui, "msgColor", color )
    return rui
}
var function HP_Rect( var topo, vector color, int sort )
{
    var rui = RuiCreate( $"ui/basic_image.rpak", topo, RUI_DRAW_HUD, sort )
    RuiSetFloat3( rui, "basicImageColor", color )
    RuiSetFloat( rui, "basicImageAlpha", 0.0 )
    return rui
}
var function HP_Topo() { return RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false ) }
void function HP_Place( var topo, float x, float y, float w, float h )
{
    RuiTopology_UpdatePos( topo, <x,y,0>, <w,0,0>, <0,h,0> )
}

void function HP_HudCreate()
{

    hpUi.fuse = CreateCockpitRui( $"ui/lockon_hud.rpak" )
    RuiSetBool( hpUi.fuse, "isVisible", false )
    foreach ( string side in ["northLock","southLock","westLock","eastLock"] ) RuiSetBool( hpUi.fuse, side, false )
    hpUi.panelTopo = HP_Topo()
    hpUi.panelBack = HP_Rect( hpUi.panelTopo, <0.015,0.02,0.03>, 109 )
    hpUi.accentTopo = HP_Topo()
    hpUi.accent = HP_Rect( hpUi.accentTopo, <1.0,0.53,0.14>, 110 )
    hpUi.barTopo = HP_Topo()
    hpUi.barBack = HP_Rect( hpUi.barTopo, <0.08,0.08,0.09>, 110 )
    hpUi.fillTopo = HP_Topo()
    hpUi.fill = HP_Rect( hpUi.fillTopo, <1.0,0.53,0.14>, 111 )
    hpUi.title = HP_Text( 30.0, <1.0,0.62,0.25> )
    hpUi.detail = HP_Text( 19.0, <0.85,0.88,0.92> )
}

void function HP_HudDestroy()
{
    foreach ( rui in [hpUi.fuse, hpUi.panelBack, hpUi.accent, hpUi.barBack, hpUi.fill, hpUi.title, hpUi.detail] )
        if ( rui != null ) RuiDestroyIfAlive( rui )
    foreach ( topo in [hpUi.panelTopo, hpUi.accentTopo, hpUi.barTopo, hpUi.fillTopo] )
        if ( topo != null ) RuiTopology_Destroy( topo )
}

void function HP_FuseThink()
{

    while ( !IsValid( GetLocalClientPlayer() ) ) WaitFrame()
    while ( true )
    {
        entity player = GetLocalClientPlayer()
        if ( hpUi.fuse != null && IsValid( player ) && GetGlobalNetEnt( "hpCarrier" ) == player )
            RuiSetString( hpUi.fuse, "lockMessage", format( "%.2f", max( 0.0, GetGlobalNetTime( "hpFuseEnd" ) - Time() ) ) )
        WaitFrame()
    }
}

string function HP_TacticalLine( entity player )
{
    if ( !player.GetPlayerNetBool( "hpTacticalClaimed" ) ) return ""
    return player.GetPlayerNetBool( "hpTacticalSpent" ) ? "\nTactical used" : "\nTactical READY  -  one use"
}

void function HP_HudUpdate( entity player, entity carrier )
{
    float fuseEnd = GetGlobalNetTime( "hpFuseEnd" )
    bool live = IsValid( carrier ) && fuseEnd > Time()
    bool mine = live && carrier == player && IsAlive( player )
    float left = max( 0.0, fuseEnd - Time() )

    RuiSetBool( hpUi.fuse, "isVisible", mine )
    if ( mine )
    {

        int second = int( ceil( left ) )
        RuiSetGameTime( hpUi.fuse, "lockEndTime", fuseEnd )
        if ( second <= 5 && second != hpUi.lastBeep ) { hpUi.lastBeep = second; EmitSoundOnEntity( player, "HUD_40mm_TrackerBeep_Locked" ); }
    }
    else hpUi.lastBeep = -1

    string title = "HOT POTATO"
    string detail = "Waiting for at least 2 pilots"
    int state = GetGlobalNetInt( "hpState" )
    if ( state == 1 )
    {
        int next = maxint( 0, int( ceil( GetGlobalNetTime( "hpNextRound" ) - Time() ) ) )
        title = format( "NEXT ROUND IN %d", next )
        detail = "Melee someone to pass the potato"
    }
    else if ( state == 2 && !live ) detail = "Round starting"
    if ( live )
    {
        title = format( "ROUND %d  -  %d ALIVE", GetGlobalNetInt( "hpRound" ), GetGlobalNetInt( "hpAlive" ) )
        if ( !IsAlive( player ) ) detail = "Eliminated  -  back next round\nPotato: " + carrier.GetPlayerName()
        else if ( mine ) detail = "YOU HAVE THE POTATO\nMelee someone to pass it"
        else detail = "Potato: " + carrier.GetPlayerName() + "\nKeep away from them"
        detail += HP_TacticalLine( player )
    }
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    float x = width*0.025
    float y = height*0.29
    float w = 380.0*s
    int lines = split( detail, "\n" ).len()
    float h = (54.0 + 24.0*lines + (live ? 20.0 : 0.0))*s
    vector hot = left < 5.0 ? <1.0,0.25,0.15> : <1.0,0.53,0.14>
    HP_Place( hpUi.panelTopo, x, y, w, h )
    HP_Place( hpUi.accentTopo, x, y, 4.0*s, h )
    RuiSetFloat( hpUi.panelBack, "basicImageAlpha", 0.72 )
    RuiSetFloat3( hpUi.accent, "basicImageColor", mine ? hot : <1.0,0.53,0.14> )
    RuiSetFloat( hpUi.accent, "basicImageAlpha", 1.0 )
    RuiSetString( hpUi.title, "msgText", title )
    RuiSetFloat2( hpUi.title, "msgPos", <(x+16.0*s)/width,(y+8.0*s)/height,0> )
    RuiSetFloat( hpUi.title, "msgAlpha", 1.0 )
    RuiSetFloat3( hpUi.detail, "msgColor", mine ? hot : <0.85,0.88,0.92> )
    RuiSetString( hpUi.detail, "msgText", detail )
    RuiSetFloat2( hpUi.detail, "msgPos", <(x+16.0*s)/width,(y+44.0*s)/height,0> )
    RuiSetFloat( hpUi.detail, "msgAlpha", 1.0 )

    float length = float( maxint( 5, GetCurrentPlaylistVarInt( "hp_fuse_seconds", 30 ) ) )
    float bx = x + 16.0*s
    float by = y + h - 16.0*s
    float bw = w - 32.0*s
    HP_Place( hpUi.barTopo, bx, by, bw, 6.0*s )
    HP_Place( hpUi.fillTopo, bx, by, max( 1.0, bw*clamp( left/length, 0.0, 1.0 ) ), 6.0*s )
    RuiSetFloat( hpUi.barBack, "basicImageAlpha", live ? 0.9 : 0.0 )
    RuiSetFloat3( hpUi.fill, "basicImageColor", hot )
    RuiSetFloat( hpUi.fill, "basicImageAlpha", live ? 1.0 : 0.0 )
}

void function HP_ClearMarkedFX()
{
    if ( file.markedFX != -1 && IsValid( file.cockpit ) && EffectDoesExist( file.markedFX ) )
        EffectStop( file.markedFX, true, false )
    file.markedFX = -1
    file.cockpit = null
}

void function HP_Presentation()
{
    bool wasMarked = false
    entity lastCarrier = null
    int lastDropState = -1
    entity lastDrop = null
    HP_HudCreate()
    thread HP_FuseThink()
    OnThreadEnd( void function()
    {
        HP_HudDestroy()
        HP_ClearMarkedFX()
        if ( file.incoming != null ) RuiDestroyIfAlive( file.incoming )
        if ( file.destination != null ) RuiDestroyIfAlive( file.destination )
        if ( file.carrierMarker != null ) RuiDestroyIfAlive( file.carrierMarker )
    } )
    while ( true )
    {
        entity player = GetLocalClientPlayer()
        if ( !IsValid( player ) ) { wait 0.1; continue; }
        entity carrier = GetGlobalNetEnt( "hpCarrier" )
        HP_HudUpdate( player, carrier )
        bool marked = IsAlive( player ) && carrier == player
        entity cockpit = player.GetCockpit()
        if ( marked != wasMarked || (marked && cockpit != file.cockpit) )
        {
            HP_ClearMarkedFX()
            if ( IsValid( cockpit ) )
            {
                if ( marked )
                {
                    file.markedFX = StartParticleEffectOnEntity( cockpit, GetParticleSystemIndex( $"P_MFD" ), FX_PATTACH_ABSORIGIN_FOLLOW, -1 )
                    file.cockpit = cockpit
                }

            }
            wasMarked = marked
        }
        if ( carrier != lastCarrier )
        {
            if ( file.carrierMarker != null ) RuiDestroyIfAlive( file.carrierMarker )
            file.carrierMarker = null
            if ( IsValid( carrier ) && carrier != player )
            {
                file.carrierMarker = CreateCockpitRui( $"ui/overhead_icon_evac.rpak", 200 )
                RuiSetImage( file.carrierMarker, "icon", $"rui/hud/gametype_icons/mfd/mfd_enemy" )

                RuiSetString( file.carrierMarker, "statusText", "Potatoman" )
                RuiSetGameTime( file.carrierMarker, "finishTime", RUI_BADGAMETIME )
                RuiSetBool( file.carrierMarker, "isVisible", true )
                RuiTrackFloat3( file.carrierMarker, "pos", carrier, RUI_TRACK_OVERHEAD_FOLLOW )
            }
            lastCarrier = carrier
        }
        int state = GetGlobalNetInt( "hpDropState" )
        entity drop = GetGlobalNetEnt( "hpDrop" )

        if ( player.GetPlayerNetBool( "hpTacticalClaimed" ) ) state = 0
        if ( state != lastDropState || drop != lastDrop )
        {
            if ( file.incoming != null ) RuiDestroyIfAlive( file.incoming )
            if ( file.destination != null ) RuiDestroyIfAlive( file.destination )
            file.incoming = null
            file.destination = null
            if ( IsValid( drop ) && state == 1 )
            {
                file.incoming = RuiCreate( $"ui/titanfall_timer.rpak", clGlobal.topoFullScreen, RUI_DRAW_HUD, 0 )
                RuiTrackFloat3( file.incoming, "playerPos", player, RUI_TRACK_ABSORIGIN_FOLLOW )
                RuiSetFloat3( file.incoming, "pos", drop.GetOrigin()+<0,0,48> )
                RuiSetGameTime( file.incoming, "impactTime", GetGlobalNetTime( "hpDropImpact" ) )
            }
            else if ( IsValid( drop ) && state == 2 )
            {
                file.destination = CreateCockpitRui( $"ui/speedball_flag_marker.rpak", 200 )
                RuiSetBool( file.destination, "playerIsCarrying", false )
                RuiSetBool( file.destination, "isCarried", false )
                RuiSetBool( file.destination, "isVisible", true )
                RuiSetFloat3( file.destination, "pos", drop.GetOrigin()+<0,0,64> )
            }
            lastDropState = state
            lastDrop = drop
        }
        wait 0.05
    }
}
