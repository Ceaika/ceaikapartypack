global function PartyCredits_Init
global function PartyCredits_Release

// credits board in the lobby. CREDITS floats over the spot, walk up and it unfolds
// into a leaderboard of me and the playtesters. yes my name is highlighted. i made it

const vector CREDITS_SPOT = <838.93, 2.75, 59.03>
const float CREDITS_SEE = 2600.0     // the floating title shows from this far
const float CREDITS_OPEN = 330.0     // the board opens this close...
const float CREDITS_CLOSE = 440.0    // ...and folds away again past this
const int CREDITS_ROWS = 8

// board layout in world units
const float BOARD_W = 212.0
const float BOARD_BOTTOM = 16.0
const float BOARD_HEADER = 40.0
const float ROW_GAP = 14.5
const float ROW_W = 190.0
const float ROW_H = 12.16            // ROW_W at the row images' 1000 x 64
const float BOARD_PAD = 10.0
const float TITLE_ASPECT = 3.449     // the title image's 369 x 107
const float TITLE_FAR_H = 34.0
const float TITLE_OPEN_H = 26.0

// world panels take srgb. hud colours come out red here
const vector CREDITS_ORANGE = <0.992,0.294,0.004>        // the loading screen's #FD4B01
const vector CREDITS_HIGHLIGHT = <0.62,0.19,0.03>        // a deeper burnt orange behind Ceaika's row
const vector CREDITS_BACK = <0.012,0.018,0.03>

const int Q_BACK = 0
const int Q_TOP = 1
const int Q_BOTTOM = 2
const int Q_HIGHLIGHT = 3
const int Q_TITLE = 4
const int Q_ROW = 5                  // Q_ROW + i: row i

struct
{
    array<var> topos
    array<var> ruis
    float floorZ = 0.0
    float openT = 0.0                // seconds into the opening (runs back when closing)
    bool open = false
    vector right = <0,1,0>
    vector toward = <1,0,0>
    bool released = false
} credits

// transition starting, give back the planes and stay off
void function PartyCredits_Release()
{
    credits.released = true
    Credits_Destroy()
}

void function PartyCredits_Init()
{
    if ( GetMapName() != "mp_coliseum" ) return
    thread PartyCredits_Run()
}

float function Credits_Ease( float u ) { u = clamp( u, 0.0, 1.0 ); return 1.0 - (1.0-u)*(1.0-u)*(1.0-u); }
float function Credits_EaseBack( float u )
{
    u = clamp( u, 0.0, 1.0 )
    float v = u - 1.0
    return 1.0 + 2.0*v*v*v + v*v
}
float function Credits_EaseInOut( float u ) { u = clamp( u, 0.0, 1.0 ); return u*u*(3.0-2.0*u); }

float function Credits_BoardH() { return BOARD_HEADER + ROW_GAP*CREDITS_ROWS + BOARD_PAD; }

bool function Credits_Create()
{
    array<asset> images = [ $"", $"", $"", $"", $"rui/ceaika/credits_title" ]
    images.extend( [ $"rui/ceaika/credits_row_0", $"rui/ceaika/credits_row_1", $"rui/ceaika/credits_row_2", $"rui/ceaika/credits_row_3",
        $"rui/ceaika/credits_row_4", $"rui/ceaika/credits_row_5", $"rui/ceaika/credits_row_6", $"rui/ceaika/credits_row_7" ] )
    foreach ( asset image in images )
    {
        var topo
        // out of topologies, try later
        try { topo = RuiTopology_CreatePlane( CREDITS_SPOT, <0,1,0>, <0,0,-1>, true ) }
        catch ( ex ) { Credits_Destroy(); return false }
        var rui = RuiCreate( $"ui/basic_image.rpak", topo, RUI_DRAW_WORLD, 0 )
        if ( image != $"" ) RuiSetImage( rui, "basicImage", image )
        RuiSetFloat( rui, "basicImageAlpha", 0.0 )
        credits.topos.append( topo )
        credits.ruis.append( rui )
    }
    RuiSetFloat3( credits.ruis[Q_BACK], "basicImageColor", CREDITS_BACK )
    RuiSetFloat3( credits.ruis[Q_TOP], "basicImageColor", CREDITS_ORANGE )
    RuiSetFloat3( credits.ruis[Q_BOTTOM], "basicImageColor", CREDITS_ORANGE )
    RuiSetFloat3( credits.ruis[Q_HIGHLIGHT], "basicImageColor", CREDITS_HIGHLIGHT )
    RuiSetFloat3( credits.ruis[Q_TITLE], "basicImageColor", CREDITS_ORANGE )
    return true
}

void function Credits_Destroy()
{
    foreach ( var rui in credits.ruis ) RuiDestroyIfAlive( rui )
    foreach ( var topo in credits.topos ) RuiTopology_Destroy( topo )
    credits.ruis.clear()
    credits.topos.clear()
}

void function PartyCredits_Run()
{
    OnThreadEnd( function() { Credits_Destroy(); } )
    TraceResults ground = TraceLine( CREDITS_SPOT, CREDITS_SPOT - <0,0,512>, null, TRACE_MASK_SOLID_BRUSHONLY, TRACE_COLLISION_GROUP_NONE )
    credits.floorZ = ground.fraction < 1.0 ? ground.endPos.z : CREDITS_SPOT.z - 60.0
    float last = Time()
    float retryAt = 0.0
    while ( true )
    {
        WaitFrame()
        float dt = Time() - last
        last = Time()
        entity player = GetLocalViewPlayer()
        if ( !IsValid( player ) ) continue
        vector eye = player.EyePosition()
        vector flat = < eye.x - CREDITS_SPOT.x, eye.y - CREDITS_SPOT.y, 0 >
        float distance = Length( flat )
        if ( distance > CREDITS_SEE )
        {
            if ( credits.ruis.len() > 0 ) Credits_Destroy()
            credits.open = false
            credits.openT = 0.0
            continue
        }
        if ( credits.released ) continue
        if ( credits.ruis.len() == 0 )
        {
            if ( Time() < retryAt ) continue
            if ( !Credits_Create() ) { retryAt = Time() + 1.0; continue; }
        }
        if ( distance > 1.0 )
        {
            credits.toward = Normalize( flat )
            credits.right = CrossProduct( credits.toward, <0,0,1> )   // the viewer's right
        }
        bool wasOpen = credits.open
        if ( distance < CREDITS_OPEN ) credits.open = true
        else if ( distance > CREDITS_CLOSE ) credits.open = false
        if ( credits.open && !wasOpen ) EmitSoundOnEntity( player, "UI_InGame_FD_InfoCardSlideIn" )
        credits.openT = credits.open ? min( credits.openT + dt, 2.0 ) : max( 0.0, min( credits.openT, 0.9 ) - dt*2.0 )
        Credits_Draw( distance )
    }
}

// flat rect facing the viewer, layers offset in depth so they dont z fight
void function Credits_Quad( int index, float x, float z, float w, float h, float depth, float alpha )
{
    vector centre = < CREDITS_SPOT.x, CREDITS_SPOT.y, credits.floorZ + z > + credits.toward*depth + credits.right*x
    // world planes only show from one side and draw from the top left, so it faces u the right way up
    vector origin = centre - credits.right*( w*0.5 ) + <0,0,h*0.5>
    RuiTopology_UpdatePos( credits.topos[index], origin, credits.right*max( w, 0.01 ), < 0, 0, -max( h, 0.01 ) > )
    RuiSetFloat( credits.ruis[index], "basicImageAlpha", w > 0.05 && h > 0.05 ? clamp( alpha, 0.0, 1.0 ) : 0.0 )
}

void function Credits_Draw( float distance )
{
    float t = credits.openT
    float boardH = Credits_BoardH()
    float top = BOARD_BOTTOM + boardH
    float shimmer = 0.9 + 0.06*sin( Time()*23.0 ) + 0.04*sin( Time()*61.0 )
    // unfold: line grows across then opens up with a little overshoot
    float across = Credits_Ease( t/0.18 )
    float tall = t <= 0.0 ? 0.0 : max( 0.012, Credits_EaseBack( (t-0.12)/0.32 ) )
    float h = boardH*tall
    float centreZ = BOARD_BOTTOM + boardH*0.5
    float back = min( 1.0, t/0.08 )
    Credits_Quad( Q_BACK, 0.0, centreZ, BOARD_W*across, h, 0.0, 0.9*back )
    Credits_Quad( Q_TOP, 0.0, centreZ + h*0.5, BOARD_W*across, 1.6, 0.3, back )
    Credits_Quad( Q_BOTTOM, 0.0, centreZ - h*0.5, BOARD_W*across, 1.6, 0.3, back )
    // title bobs from afar, becomes the header when open
    float move = Credits_EaseInOut( t/0.4 )
    float far = clamp( ( CREDITS_SEE - distance )/600.0, 0.0, 1.0 )
    float floatZ = top + 18.0 + 4.0*sin( Time()*1.7 )
    float titleH = TITLE_FAR_H + ( TITLE_OPEN_H - TITLE_FAR_H )*move
    float titleZ = floatZ + ( top - BOARD_HEADER*0.5 - floatZ )*move
    Credits_Quad( Q_TITLE, 0.0, titleZ, titleH*TITLE_ASPECT, titleH, 0.6, far*shimmer )
    // rows slide in one by one, mine on the orange bar
    for ( int i = 0; i < CREDITS_ROWS; i++ )
    {
        float e = Credits_Ease( (t - 0.32 - 0.05*i)/0.25 )
        float z = top - BOARD_HEADER - ROW_GAP*( i + 0.5 )
        Credits_Quad( Q_ROW + i, -22.0*( 1.0 - e ), z, ROW_W, ROW_H, 0.6, e*shimmer )
        if ( i == 0 ) Credits_Quad( Q_HIGHLIGHT, 0.0, z, ( BOARD_W - 8.0 )*e, ROW_GAP - 1.0, 0.3, 0.9*e )
    }
}
