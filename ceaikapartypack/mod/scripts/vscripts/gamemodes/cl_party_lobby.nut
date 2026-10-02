untyped
global function Cl_PartyLobby_Init

const int PL_SLOTS = 12
const int PL_MODES = 9
const vector PL_ACCENT = <0.35,0.82,1.0>
const vector PL_GO = <0.3,0.92,0.55>
const vector PL_TEXT = <0.95,0.97,1.0>
const vector PL_STATUS = <0.78,0.84,0.9>
const vector PL_AMBER = <1.0,0.67,0.27>
const vector PL_TEAL = <0.25,0.9,0.8>
const vector PL_DIM = <0.55,0.6,0.66>

const string PL_MUSIC = "music_timeshift_elevator_bossanova"

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
    var leadName
    var leadDetail
    var mine

    var readyTopo
    var ready
    var readyAccentTopo
    var readyAccent
    var readyHead
    var readyNames
    var readyYes
    var readyWait

    var holdBackTopo
    var holdBack
    var holdFillTopo
    var holdFill
    var holdText
    bool music = false
    int musicRun = 0
} plHud

void function Cl_PartyLobby_Init()
{
    thread PartyLobby_HUD()
    PartyCredits_Init()
    PartyVoteBoards_Init()
    PartyStatue_ClientInit()
}

string function PartyLobby_ModeName( int index )
{
    array<string> names = ["JUGGERNAUT","HOT POTATO","PROP HUNT","BODY SWAP","FREE FOR ALL","THE HIDDEN","ONE IN THE CHAMBER","GUN GAME","INFECTION"]
    return index >= 0 && index < names.len() ? names[index] : ""
}

var function PartyLobby_Text( asset kind, float size, vector color, int lines )
{
    var rui = CreateFullscreenRui( kind, 120 )
    RuiSetInt( rui, "maxLines", lines )
    RuiSetInt( rui, "lineNum", 0 )
    RuiSetFloat( rui, "thicken", 0.0 )
    RuiSetFloat( rui, "msgFontSize", size )
    RuiSetFloat3( rui, "msgColor", color )
    RuiSetFloat( rui, "msgAlpha", 0.0 )
    return rui
}

var function PartyLobby_Rect( var topo, vector color, int sort )
{
    var rui = RuiCreate( $"ui/basic_image.rpak", topo, RUI_DRAW_HUD, sort )
    RuiSetFloat3( rui, "basicImageColor", color )
    RuiSetFloat( rui, "basicImageAlpha", 0.0 )
    return rui
}

var function PartyLobby_Plane()
{
    return RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false )
}

void function PartyLobby_Place( var topo, float x, float y, float w, float h )
{
    RuiTopology_UpdatePos( topo, <x,y,0>, <w,0,0>, <0,h,0> )
}

void function PartyLobby_Line( var rui, string text, vector color, float x, float y, bool live )
{
    RuiSetString( rui, "msgText", text )
    RuiSetFloat3( rui, "msgColor", color )
    RuiSetFloat( rui, "msgAlpha", live && text != "" ? 0.95 : 0.0 )
    RuiSetFloat2( rui, "msgPos", <x/GetScreenSize()[0], y/GetScreenSize()[1], 0> )
}

void function PartyLobby_Create()
{
    asset CENTER = $"ui/cockpit_console_text_center.rpak"
    asset LEFT = $"ui/cockpit_console_text_top_left.rpak"
    plHud.cardTopo = PartyLobby_Plane()
    plHud.card = PartyLobby_Rect( plHud.cardTopo, <0.015,0.02,0.03>, 98 )
    plHud.accentTopo = PartyLobby_Plane()
    plHud.accent = PartyLobby_Rect( plHud.accentTopo, PL_ACCENT, 99 )
    plHud.barTopo = PartyLobby_Plane()
    plHud.bar = PartyLobby_Rect( plHud.barTopo, <0.1,0.11,0.13>, 99 )
    plHud.fillTopo = PartyLobby_Plane()
    plHud.fill = PartyLobby_Rect( plHud.fillTopo, PL_ACCENT, 100 )
    plHud.heading = PartyLobby_Text( LEFT, 18.0, PL_ACCENT, 1 )
    plHud.clock = PartyLobby_Text( LEFT, 40.0, PL_TEXT, 1 )
    plHud.status = PartyLobby_Text( LEFT, 18.0, PL_STATUS, 2 )
    plHud.leadName = PartyLobby_Text( LEFT, 17.0, PL_AMBER, 1 )
    plHud.leadDetail = PartyLobby_Text( LEFT, 15.0, PL_STATUS, 1 )
    plHud.mine = PartyLobby_Text( LEFT, 15.0, PL_TEAL, 1 )
    plHud.readyTopo = PartyLobby_Plane()
    plHud.ready = PartyLobby_Rect( plHud.readyTopo, <0.015,0.02,0.03>, 98 )
    plHud.readyAccentTopo = PartyLobby_Plane()
    plHud.readyAccent = PartyLobby_Rect( plHud.readyAccentTopo, PL_ACCENT, 99 )
    plHud.readyHead = PartyLobby_Text( LEFT, 18.0, PL_ACCENT, 1 )
    plHud.readyNames = PartyLobby_Text( LEFT, 16.0, PL_TEXT, PL_SLOTS )
    plHud.readyYes = PartyLobby_Text( LEFT, 16.0, PL_GO, PL_SLOTS )
    plHud.readyWait = PartyLobby_Text( LEFT, 16.0, PL_DIM, PL_SLOTS )
    plHud.holdBackTopo = PartyLobby_Plane()
    plHud.holdBack = PartyLobby_Rect( plHud.holdBackTopo, <0.1,0.11,0.13>, 112 )
    plHud.holdFillTopo = PartyLobby_Plane()
    plHud.holdFill = PartyLobby_Rect( plHud.holdFillTopo, PL_ACCENT, 113 )
    plHud.holdText = PartyLobby_Text( CENTER, 18.0, PL_TEXT, 1 )
}

void function PartyLobby_HUD()
{
    while ( !IsValid( GetLocalClientPlayer() ) ) WaitFrame()
    PartyLobby_Create()
    while ( true )
    {
        bool live = GetGameState() == eGameState.Playing
        float bottom = PartyLobby_DrawCard( live )
        PartyLobby_DrawReady( live, bottom )
        PartyLobby_DrawHold( live )

        PartyLobby_Music( GetGameState() <= eGameState.Playing && GetGlobalNetInt( "plChosen" ) < 0 )
        WaitFrame()
    }
}

void function PartyLobby_Music( bool on )
{
    if ( on == plHud.music ) return
    entity player = GetLocalClientPlayer()
    if ( !IsValid( player ) ) return
    plHud.music = on
    plHud.musicRun++
    if ( on ) thread PartyLobby_MusicLoop( player, plHud.musicRun )
    else FadeOutSoundOnEntity( player, PL_MUSIC, 2.0 )
}

void function PartyLobby_MusicLoop( entity player, int run )
{
    player.EndSignal( "OnDestroy" )
    float length = GetSoundDuration( PL_MUSIC )
    printt( "[PartyLobby] lobby music, " + length + " s per loop" )
    if ( length < 5.0 ) length = 60.0
    while ( plHud.musicRun == run )
    {
        EmitSoundOnEntity( player, PL_MUSIC )
        float next = Time() + length
        while ( plHud.musicRun == run && Time() < next ) WaitFrame()
    }
}

int function PartyLobby_Need( int total )
{
    return maxint( 1, total / 2 + 1 )
}

int function PartyLobby_Leading()
{
    int best = 0
    int leader = -1
    for ( int i = 0; i < PL_MODES; i++ )
    {
        int votes = GetGlobalNetInt( "plVotes" + i )
        if ( votes > best ) { best = votes; leader = i; }
        else if ( votes == best && votes > 0 ) leader = -2
    }
    return leader
}

float function PartyLobby_DrawCard( bool live )
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    float w = 420.0*s
    float x = min( 0.76*width, width - w - 8.0*s )
    float y = 0.12*height
    float tx = x + 16.0*s
    int ready = GetGlobalNetInt( "plReadyCount" )
    int total = GetGlobalNetInt( "plPlayerCount" )
    int chosen = GetGlobalNetInt( "plChosen" )
    float deadline = GetGlobalNetTime( "plDeadline" )
    float length = float( maxint( 1, GetGlobalNetInt( "plCountdownTotal" ) ) )
    bool counting = deadline > 0.0 && chosen < 0
    bool everyone = total > 0 && ready >= total
    float left = max( 0.0, deadline - Time() )
    int secs = int( ceil( left ) )
    vector accent = everyone ? PL_GO : PL_ACCENT

    string heading = "PARTY LOBBY  /  NEXT MATCH"
    string clock = counting ? format( "%d:%02d", secs/60, secs%60 ) : ""
    string status = ""
    if ( chosen >= 0 ) { heading = "PARTY LOBBY  /  STARTING"; clock = PartyLobby_ModeName( chosen ); }
    else if ( everyone ) status = "EVERYONE READY  /  " + ready + " OF " + total
    else if ( counting ) status = "MAJORITY READY  /  " + ready + " OF " + total + "\nEVERYONE READY CUTS IT TO 10 SECONDS"
    else status = "WAITING FOR PLAYERS TO READY UP\n" + ready + " OF " + total + " READY  /  " + PartyLobby_Need( total ) + " NEEDED TO START"

    int leader = PartyLobby_Leading()
    string leadName = ""
    string leadDetail = ""
    if ( chosen < 0 )
    {
        if ( leader >= 0 )
        {
            int votes = GetGlobalNetInt( "plVotes" + leader )
            leadName = "LEADING  /  " + PartyLobby_ModeName( leader )
            leadDetail = votes + ( votes == 1 ? " VOTE" : " VOTES" )
        }
        else if ( leader == -2 ) { leadName = "VOTE TIED"; leadDetail = "A tied mode is picked at random"; }
        else
        {
            leadName = "NO VOTES YET"
            int last = GetGlobalNetInt( "plLastMode" )
            leadDetail = last >= 0 ? "Random mode, not " + PartyLobby_ModeName( last ) : "Random mode"
        }
    }
    entity me = GetLocalClientPlayer()
    int myVote = IsValid( me ) ? me.GetPlayerNetInt( "plVote" ) : -1
    bool meReady = IsValid( me ) && me.GetPlayerNetBool( "plReady" )
    string mine = ""
    if ( chosen < 0 )
    {
        if ( myVote < 0 ) mine = "PRESS %use% AT A SCREEN TO VOTE"
        else if ( !meReady ) mine = "YOUR VOTE  /  " + PartyLobby_ModeName( myVote ) + "   HOLD %use% TO READY UP"
        else mine = "YOUR VOTE  /  " + PartyLobby_ModeName( myVote ) + "   READY"
    }

    int statusLines = status == "" ? 0 : split( status, "\n" ).len()
    bool bigClock = clock != ""
    bool showBar = counting
    float statusY = y + ( bigClock ? ( showBar ? 100.0 : 86.0 ) : 38.0 )*s
    float leadY = statusY + ( statusLines*23.0 + ( statusLines > 0 ? 8.0 : 0.0 ) )*s
    float mineY = leadY + ( leadName != "" ? 52.0 : 0.0 )*s
    float h = mineY - y + ( mine != "" ? 30.0 : 4.0 )*s

    PartyLobby_Place( plHud.cardTopo, x, y, w, h )
    PartyLobby_Place( plHud.accentTopo, x, y, 4.0*s, h )
    RuiSetFloat( plHud.card, "basicImageAlpha", live ? 0.66 : 0.0 )
    RuiSetFloat3( plHud.accent, "basicImageColor", accent )
    RuiSetFloat( plHud.accent, "basicImageAlpha", live ? 1.0 : 0.0 )
    float barW = w - 32.0*s
    float frac = clamp( left / length, 0.0, 1.0 )
    PartyLobby_Place( plHud.barTopo, tx, y + 84.0*s, barW, 5.0*s )
    PartyLobby_Place( plHud.fillTopo, tx, y + 84.0*s, max( 1.0, barW*frac ), 5.0*s )
    RuiSetFloat( plHud.bar, "basicImageAlpha", live && showBar ? 0.9 : 0.0 )
    RuiSetFloat3( plHud.fill, "basicImageColor", secs <= 5 ? <1.0,0.3,0.2> : accent )
    RuiSetFloat( plHud.fill, "basicImageAlpha", live && showBar ? 1.0 : 0.0 )
    PartyLobby_Line( plHud.heading, heading, accent, tx, y + 10.0*s, live )
    PartyLobby_Line( plHud.clock, clock, counting && secs <= 5 ? <1.0,0.35,0.25> : PL_TEXT, tx, y + 30.0*s, live )
    PartyLobby_Line( plHud.status, status, PL_STATUS, tx, statusY, live )
    PartyLobby_Line( plHud.leadName, leadName, PL_AMBER, tx, leadY, live )
    PartyLobby_Line( plHud.leadDetail, leadDetail, PL_STATUS, tx, leadY + 22.0*s, live )
    PartyLobby_Line( plHud.mine, mine, PL_TEAL, tx, mineY, live )
    return y + h
}

void function PartyLobby_DrawReady( bool live, float top )
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    array<entity> players
    foreach ( entity p in GetPlayerArray() ) if ( IsValid( p ) && !IsPrivateMatchSpectator( p ) ) players.append( p )
    int rows = minint( players.len(), PL_SLOTS )
    string names = ""
    string yes = ""
    string waiting = ""
    for ( int i = 0; i < rows; i++ )
    {
        bool isReady = players[i].GetPlayerNetBool( "plReady" )
        string name = players[i].GetPlayerName()
        if ( name.len() > 18 ) name = name.slice( 0, 17 ) + "."
        string gap = i == 0 ? "" : "\n"
        names += gap + name
        yes += gap + ( isReady ? "READY" : " " )
        waiting += gap + ( isReady ? " " : "NOT READY" )
    }
    int ready = GetGlobalNetInt( "plReadyCount" )
    int total = maxint( GetGlobalNetInt( "plPlayerCount" ), players.len() )
    float w = 420.0*s
    float x = min( 0.76*width, width - w - 8.0*s )
    float y = top + 10.0*s
    float h = ( 44.0 + 22.0*rows + 8.0 )*s
    PartyLobby_Place( plHud.readyTopo, x, y, w, h )
    PartyLobby_Place( plHud.readyAccentTopo, x, y, 4.0*s, h )
    RuiSetFloat( plHud.ready, "basicImageAlpha", live ? 0.66 : 0.0 )
    RuiSetFloat3( plHud.readyAccent, "basicImageColor", total > 0 && ready >= total ? PL_GO : PL_ACCENT )
    RuiSetFloat( plHud.readyAccent, "basicImageAlpha", live ? 1.0 : 0.0 )
    float tx = x + 16.0*s
    PartyLobby_Line( plHud.readyHead, "READY UP  /  " + ready + " OF " + total, total > 0 && ready >= total ? PL_GO : PL_ACCENT, tx, y + 10.0*s, live )
    PartyLobby_Line( plHud.readyNames, names, PL_TEXT, tx, y + 40.0*s, live )
    PartyLobby_Line( plHud.readyYes, yes, PL_GO, x + w - 120.0*s, y + 40.0*s, live )
    PartyLobby_Line( plHud.readyWait, waiting, PL_DIM, x + w - 120.0*s, y + 40.0*s, live )
}

void function PartyLobby_DrawHold( bool live )
{
    entity player = GetLocalClientPlayer()
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    float started = IsValid( player ) ? player.GetPlayerNetTime( "plHoldStart" ) : 0.0
    bool shown = live && started > 0.0
    float frac = shown ? clamp( (Time()-started)/1.0, 0.0, 1.0 ) : 0.0
    float w = 260.0*s
    float x = width*0.5 - w*0.5
    float y = height*0.5 + 60.0*s
    PartyLobby_Place( plHud.holdBackTopo, x, y, w, 5.0*s )
    PartyLobby_Place( plHud.holdFillTopo, x, y, max( 0.5, w*frac ), 5.0*s )
    RuiSetFloat( plHud.holdBack, "basicImageAlpha", shown ? 0.9 : 0.0 )
    RuiSetFloat( plHud.holdFill, "basicImageAlpha", shown ? 1.0 : 0.0 )
    bool ready = IsValid( player ) && player.GetPlayerNetBool( "plReady" )
    RuiSetFloat3( plHud.holdFill, "basicImageColor", ready ? PL_AMBER : PL_GO )
    RuiSetString( plHud.holdText, "msgText", ready ? "UN-READYING..." : "READYING UP..." )
    RuiSetFloat2( plHud.holdText, "msgPos", <0, (y-20.0*s)/height-0.5, 0> )
    RuiSetFloat( plHud.holdText, "msgAlpha", shown ? 1.0 : 0.0 )
}
