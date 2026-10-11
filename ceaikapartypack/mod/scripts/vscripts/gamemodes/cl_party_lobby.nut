untyped
global function Cl_PartyLobby_Init

// Party lobby HUD, in the same style as the Juggernaut round card:
//   round card (top right): heading, countdown clock with its bar, how many
//     are ready and how many are needed, the leading vote and your vote;
//   ready card under it: everyone in the lobby, READY / NOT READY;
//   (the mode names, votes and descriptions over the screens are holograms:
//   cl_party_votes.nut);
//   the hold-to-ready bar under the crosshair.
const int PL_SLOTS = 16
const int PL_MODES = 11
const vector PL_ACCENT = <1.0,0.32,0.06>  // the Party Pack orange (the intro and transition card)
const vector PL_GO = <0.3,0.92,0.55>      // everyone ready
const vector PL_TEXT = <0.95,0.97,1.0>
const vector PL_STATUS = <0.78,0.84,0.9>
const vector PL_AMBER = <1.0,0.67,0.27>
const vector PL_TEAL = <0.25,0.9,0.8>
const vector PL_DIM = <0.55,0.6,0.66>
// Effect and Cause's elevator bossa nova, from the base game's sound bank.
const string PL_MUSIC = "music_timeshift_elevator_bossanova"

struct
{
    // round card
    array<var> pool           // planes set aside up front, all or none (PartyLobby_Reserve)
    var titleTopo             // "Party Lobby" in the intro's font
    var title
    array<var> digitTopos     // the countdown in the intro's font, with shadows
    array<var> digits
    array<var> digitShadows
    var modeTopo              // the chosen mode's name, once it is picked
    var modeImage
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
    // ready card
    var readyTopo
    var ready
    var readyAccentTopo
    var readyAccent
    var readyHead
    var readyNames
    var readyYes
    var readyWait
    // hold to ready
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

// Same order as the server's lobby.modes.
string function PartyLobby_ModeName( int index )
{
    array<string> names = ["JUGGERNAUT","HOT POTATO","PROP HUNT","BODY SWAP","FREE FOR ALL","THE HIDDEN","ONE IN THE CHAMBER","GUN GAME","INFECTION","GTFO","HUSH"]
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
    return plHud.pool.pop()
}

// The client has 64 RUI topologies in all and the lobby's holograms take a lot
// of them: take every plane the HUD needs at once, or none and try again later.
bool function PartyLobby_Reserve( int count )
{
    for ( int i = 0; i < count; i++ )
    {
        var topo = null
        try { topo = RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false ) }
        catch ( ex )
        {
            foreach ( var held in plHud.pool ) RuiTopology_Destroy( held )
            plHud.pool.clear()
            return false
        }
        plHud.pool.append( topo )
    }
    return true
}

void function PartyLobby_Place( var topo, float x, float y, float w, float h )
{
    RuiTopology_UpdatePos( topo, <x,y,0>, <w,0,0>, <0,h,0> )
}

// A line of the top-left text kind, by screen pixels.
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
    plHud.titleTopo = PartyLobby_Plane()
    plHud.title = PartyLobby_Rect( plHud.titleTopo, PL_ACCENT, 100 )
    RuiSetImage( plHud.title, "basicImage", PartyName_Image( "partylobby" ) )
    for ( int i = 0; i < 2; i++ )
    {
        plHud.digitTopos.append( PartyLobby_Plane() )
        plHud.digitShadows.append( PartyLobby_Rect( plHud.digitTopos[2*i], <0.18,0.004,0.0>, 100 ) )
        plHud.digitTopos.append( PartyLobby_Plane() )
        plHud.digits.append( PartyLobby_Rect( plHud.digitTopos[2*i+1], PL_TEXT, 101 ) )
    }
    plHud.modeTopo = PartyLobby_Plane()
    plHud.modeImage = PartyLobby_Rect( plHud.modeTopo, PL_ACCENT, 100 )
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
    // 8 card and bar planes, the title, two digits with shadows, the mode name.
    while ( !PartyLobby_Reserve( 14 ) ) wait 1.0
    PartyLobby_Create()
    while ( true )
    {
        bool live = GetGameState() == eGameState.Playing
        float bottom = PartyLobby_DrawCard( live )
        PartyLobby_DrawReady( live, bottom )
        PartyLobby_DrawHold( live )
        // From arrival until a mode is picked.
        PartyLobby_Music( GetGameState() <= eGameState.Playing && GetGlobalNetInt( "plChosen" ) < 0 )
        WaitFrame()
    }
}

// Elevator music while the lobby is open. It fades out when a mode is picked,
// under the "starting a new game" transition.
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

// The track plays once per emit: start it again each time it ends. A newer
// run (music stopped and started again) replaces this one.
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

// Ready players needed before the countdown starts (more than half).
int function PartyLobby_Need( int total )
{
    return maxint( 1, total / 2 + 1 )
}

// The mode with the most votes, -1 for none, -2 for a tie.
int function PartyLobby_Leading()
{
    int best = 0
    int leader = -1
    for ( int i = 0; i < PL_MODES; i++ )
    {
        if ( !PartyLobby_ModeEnabled( i ) ) continue
        int votes = GetGlobalNetInt( "plVotes" + i )
        if ( votes > best ) { best = votes; leader = i; }
        else if ( votes == best && votes > 0 ) leader = -2
    }
    return leader
}

// The lobby card, top right: "Party Lobby" in the intro's font, the countdown
// in the same font with its bar (or the chosen mode's name once it is picked),
// then a few plain lines: how many are ready, what the vote looks like and what
// you have done. Returns its bottom edge.
float function PartyLobby_DrawCard( bool live )
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    float w = 420.0*s
    float x = min( 0.76*width, width - w - 8.0*s )
    float y = 0.12*height
    float tx = x + 18.0*s
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

    string status = ""
    if ( chosen < 0 )
    {
        if ( everyone ) status = "Everyone's ready"
        else if ( counting ) status = ready + " of " + total + " ready\nEveryone ready cuts it to 10 seconds"
        else status = ready + " of " + total + " ready, " + PartyLobby_Need( total ) + " needed to start"
    }
    string leadName = ""
    string leadDetail = ""
    if ( chosen < 0 )
    {
        int leader = PartyLobby_Leading()
        if ( leader >= 0 )
        {
            int votes = GetGlobalNetInt( "plVotes" + leader )
            leadName = PartyLobby_ModeName( leader ) + " leads with " + votes + ( votes == 1 ? " vote" : " votes" )
        }
        else if ( leader == -2 ) { leadName = "The vote is tied"; leadDetail = "One of the tied modes will be picked"; }
        else
        {
            leadName = "No votes yet"
            int last = GetGlobalNetInt( "plLastMode" )
            leadDetail = last >= 0 ? "A random mode other than " + PartyLobby_ModeName( last ) + " will be picked" : "A random mode will be picked"
        }
    }
    entity me = GetLocalClientPlayer()
    int myVote = IsValid( me ) ? me.GetPlayerNetInt( "plVote" ) : -1
    bool meReady = IsValid( me ) && me.GetPlayerNetBool( "plReady" )
    string mine = ""
    if ( chosen < 0 )
    {
        if ( myVote < 0 ) mine = "Walk up to a screen and press %use% to vote"
        else if ( !meReady ) mine = "You voted for " + PartyLobby_ModeName( myVote ) + ". Hold %use% to ready up"
        else mine = "You voted for " + PartyLobby_ModeName( myVote ) + ". You're ready"
    }

    // Top to bottom, in 1080p pixels scaled to the screen.
    float titleH = 36.0*s
    PartyLobby_Place( plHud.titleTopo, tx, y + 14.0*s, titleH*PartyName_Aspect( "partylobby" ), titleH )
    RuiSetFloat3( plHud.title, "basicImageColor", accent )
    RuiSetFloat( plHud.title, "basicImageAlpha", live ? 1.0 : 0.0 )
    float cy = y + 14.0*s + titleH + 12.0*s

    // The chosen mode's name, big.
    bool picked = chosen >= 0
    if ( picked )
    {
        string key = PartyLobby_ModeKey( chosen )
        float mh = 50.0*s
        RuiSetImage( plHud.modeImage, "basicImage", PartyName_Image( key ) )
        PartyLobby_Place( plHud.modeTopo, tx, cy, mh*PartyName_Aspect( key ), mh )
        cy += mh + 14.0*s
    }
    RuiSetFloat( plHud.modeImage, "basicImageAlpha", live && picked ? 1.0 : 0.0 )

    // The countdown: seconds in the intro's font, and the bar under them.
    string digits = counting ? string( minint( 99, secs ) ) : ""
    float dh = 58.0*s
    float dx = tx
    for ( int i = 0; i < 2; i++ )
    {
        bool shown = live && i < digits.len()
        if ( shown )
        {
            string glyph = digits.slice( i, i + 1 )
            float dw = dh*PartyScore_Aspect( glyph )
            RuiSetImage( plHud.digits[i], "basicImage", PartyScore_Image( glyph ) )
            RuiSetImage( plHud.digitShadows[i], "basicImage", PartyScore_Image( glyph ) )
            PartyLobby_Place( plHud.digitTopos[2*i], dx + 3.0*s, cy + 4.0*s, dw, dh )
            PartyLobby_Place( plHud.digitTopos[2*i+1], dx, cy, dw, dh )
            RuiSetFloat3( plHud.digits[i], "basicImageColor", secs <= 5 ? <1.0,0.35,0.25> : PL_TEXT )
            dx += dw*0.94
        }
        RuiSetFloat( plHud.digits[i], "basicImageAlpha", shown ? 1.0 : 0.0 )
        RuiSetFloat( plHud.digitShadows[i], "basicImageAlpha", shown ? 0.5 : 0.0 )
    }
    float barW = w - 36.0*s
    if ( counting )
    {
        cy += dh + 10.0*s
        PartyLobby_Place( plHud.barTopo, tx, cy, barW, 5.0*s )
        PartyLobby_Place( plHud.fillTopo, tx, cy, max( 1.0, barW*clamp( left / length, 0.0, 1.0 ) ), 5.0*s )
        cy += 5.0*s + 14.0*s
    }
    RuiSetFloat( plHud.bar, "basicImageAlpha", live && counting ? 0.9 : 0.0 )
    RuiSetFloat3( plHud.fill, "basicImageColor", secs <= 5 ? <1.0,0.3,0.2> : accent )
    RuiSetFloat( plHud.fill, "basicImageAlpha", live && counting ? 1.0 : 0.0 )

    // The lines.
    PartyLobby_Line( plHud.heading, "", accent, tx, y, false )
    PartyLobby_Line( plHud.clock, "", PL_TEXT, tx, y, false )
    int statusLines = status == "" ? 0 : split( status, "\n" ).len()
    PartyLobby_Line( plHud.status, status, PL_STATUS, tx, cy, live )
    cy += ( statusLines*23.0 + ( statusLines > 0 ? 10.0 : 0.0 ) )*s
    PartyLobby_Line( plHud.leadName, leadName, PL_AMBER, tx, cy, live )
    if ( leadName != "" ) cy += 23.0*s
    PartyLobby_Line( plHud.leadDetail, leadDetail, PL_STATUS, tx, cy, live )
    if ( leadDetail != "" ) cy += 23.0*s
    if ( leadName != "" ) cy += 10.0*s
    PartyLobby_Line( plHud.mine, mine, PL_TEAL, tx, cy, live )
    if ( mine != "" ) cy += 23.0*s
    float h = cy - y + 12.0*s

    PartyLobby_Place( plHud.cardTopo, x, y, w, h )
    PartyLobby_Place( plHud.accentTopo, x, y, 4.0*s, h )
    RuiSetFloat( plHud.card, "basicImageAlpha", live ? 0.66 : 0.0 )
    RuiSetFloat3( plHud.accent, "basicImageColor", accent )
    RuiSetFloat( plHud.accent, "basicImageAlpha", live ? 1.0 : 0.0 )
    return y + h
}

// Same order as the server's lobby.modes; the keys of the name images.
string function PartyLobby_ModeKey( int index )
{
    array<string> keys = ["jugg","hotpotato","prophunt","bodyswap","ffa","hidden","chamber","gg","inf","gtfo","echo"]
    return index >= 0 && index < keys.len() ? keys[index] : ""
}

// Everyone in the lobby and whether they are ready, in a card under the round card.
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
        yes += gap + ( isReady ? "Ready" : " " )
        waiting += gap + ( isReady ? " " : "Not ready" )
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
    PartyLobby_Line( plHud.readyHead, "Players, " + ready + " of " + total + " ready", total > 0 && ready >= total ? PL_GO : PL_ACCENT, tx, y + 10.0*s, live )
    PartyLobby_Line( plHud.readyNames, names, PL_TEXT, tx, y + 40.0*s, live )
    PartyLobby_Line( plHud.readyYes, yes, PL_GO, x + w - 120.0*s, y + 40.0*s, live )
    PartyLobby_Line( plHud.readyWait, waiting, PL_DIM, x + w - 120.0*s, y + 40.0*s, live )
}

// Progress bar under the crosshair while holding Use to ready up.
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
