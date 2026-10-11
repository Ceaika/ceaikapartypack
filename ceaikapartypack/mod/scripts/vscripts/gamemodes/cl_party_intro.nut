untyped
global function PartyIntro_Init
global function PartyTransition

// The orange card. The loading screen (the pack's loadingprogress.res, built by
// artifacts/ceaika-loadscreen) is the card in its corner layout: "Ceaika's
// Partypack" in the top-left corner, the map's name huge on the right with the
// mode under it, and the RE-45 spinning in the bottom-left corner. Leaving a map the card settles
// into that layout, and arriving it starts from it, so the map change reads as
// one continuous screen.
//
// Arriving in a fresh match (not when joining one in progress): everything but
// the gun fades, the gun grows back to the middle, "Ceaika's" slides out of its
// barrel, "Partypack" flies in and slams into it, "presents..." rises in. When
// the match starts the gun fires: a white line shoots out of the barrel, the gun
// slides away to the left as if we follow the bullet, and the card opens along
// the line, the top half up and the bottom half down. "presents..." stays until
// the mode's title banner goes. Arriving in the lobby plays the same, faster.
// Images come from ceaika_ui.rpak (artifacts/ceaika-ui-pak).
const vector INTRO_ORANGE = <0.9823,0.0704,0.0003> // #FD4B01 (the HUD takes linear colour, not sRGB)
const vector INTRO_FLASH = <1.0,0.25,0.06>          // brighter orange for the impact flash
const vector INTRO_SHADOW = <0.18,0.004,0.0>        // deep red-brown drop shadow
const float INTRO_HOLD = 5.2       // earliest reveal of the game
const float INTRO_MAX_HOLD = 25.0  // never cover the game longer than this
const float INTRO_IMPACT = 3.6     // "Partypack" hits the gun
const float INTRO_READY = 4.2      // the logo has settled
const int INTRO_SORT = 5000
// The intro clip ships in the mod (audio/, built by artifacts/intro-music) as a
// replacement for this campaign-only music event, so nothing else is affected.
const string INTRO_MUSIC = "music_beacon_24a_blisktease"
const string HUSH_GLITCH_MUSIC = "music_s2s_00a_intro"
// The gun's muzzle (1080p pixels from the screen centre, the gun in the middle):
// the bullet line and the opening run along its height.
const float MUZZLE_X = 7.0
const float MUZZLE_Y = -204.0
// The corner layout, as on the loading screen (artifacts/ceaika-loadscreen,
// loadscreen.py): x from the left (or from the right edge for the names), y
// from the top, 1080p pixels; centres.
const float CORNER_GUN_X = 175.0
const float CORNER_GUN_Y = 950.0
const float CORNER_GUN_SCALE = 0.26
const float CORNER_SPIN = 100.0     // degrees a second, clockwise (the engine's spinner: 36 frames, ~10 a second)
const float CORNER_CEAIKAS_X = 308.1
const float CORNER_CEAIKAS_Y = 94.7
const float CORNER_CEAIKAS_SCALE = 0.82
const float CORNER_PARTYPACK_X = 423.9
const float CORNER_PARTYPACK_Y = 205.8
const float CORNER_PARTYPACK_SCALE = 0.64
const float CORNER_NAMES_RIGHT = 90.3
const float CORNER_MAP_Y = 449.2
const float CORNER_MAP_H = 59.1    // the name images' height (capitals)
const float CORNER_MODE_Y = 548.4
const float CORNER_MODE_H = 47.2    // the name images' height (tallest letters to the tails of g, p...)
// The loading screen draws the names as text, and the game caps text at about
// VGUI_MAX_TALL pixels whatever the layout asks (its fonts there are 86 and
// 62 units tall, under the cap up to 1600p): on bigger screens the names come
// out smaller. The card draws them at that size too, so nothing jumps when
// the loading screen takes over.
const float VGUI_MAX_TALL = 128.0
const float LOADING_MAP_FONT = 86.0
const float LOADING_MODE_FONT = 62.0
const float CARD_LINE_Y = 265.0     // "presents...", "redirecting to lobby...", "starting a new game..."
const float CARD_STARTING_MODE_Y = 380.0
const float CARD_STARTING_MODE_H = 62.0
// The reveal, in seconds after the shot is called.
const float FIRE_AT = 0.2           // the title has gone: fire
const float FIRE_SLIDE = 0.3        // the gun starts sliding away
const float FIRE_OPEN = 0.95        // the card starts opening along the line
const float FIRE_DONE = 1.6
const string FIRE_SOUND = "weapon_re45auto_firstshot_1p"   // the RE-45's own shot
const float IRIS_OPEN = 0.6         // arriving in the lobby: the hole takes this long to fill the screen

struct IntroImage
{
    var topo
    var rui
    var shadowTopo
    var shadow
    float w
    float h
    float drawX = 0.0
    float drawY = 0.0
    float drawScale = 1.0
    float drawDegrees = 0.0
}

// One card, as arrays: the images, and the fallback text for a map or mode
// with no name image (a map from another mod).
const int CARD_TOP = 0          // the orange, above and below the muzzle's line
const int CARD_BOTTOM = 1
const int CARD_GUN = 2
const int CARD_CEAIKAS = 3
const int CARD_PARTYPACK = 4
const int CARD_MASK = 5         // hides "Ceaika's" inside the barrel
const int CARD_LINE = 6         // "presents..." or a transition's line
const int CARD_FLASH = 7
const int CARD_BULLET = 8       // the bullet's white line
const int CARD_MAP = 9          // name images (or nothing: see texts)
const int CARD_MODE = 10
const int CARD_IRIS = 11        // the lobby's card only: the round hole and the orange beside it
const int CARD_IRIS_LEFT = 12
const int CARD_IRIS_RIGHT = 13

struct
{
    float started = 0.0
    bool musicPlaying = false
    bool hushPlaying = false
    string musicEvent = INTRO_MUSIC
    float zoom = 1.0
    bool quick = false // stock modes: reveal the game as soon as the gun is back
    string nextMode = "" // where the next map change goes (party_next from the server)
    string nextMap = ""
    float spinFrom = 0.0 // the corner gun's spin when the arrival starts
    float clock = 0.0    // PartyIntro_Clock
    float clockAt = 0.0
} intro

void function PartyIntro_Init()
{
    AddServerToClientStringCommandCallback( "party_next", PartyIntro_NextCommand )
    // The private-match lobby still reports the previous mode: never play there.
    if ( GetMapName() == "mp_lobby" ) return
    if ( GAMETYPE == "partylobby" )
    {
        thread PartyTransition_Arrive()
        return
    }
    if ( ["ffa","hidden","chamber","gg","inf","gtfo","echo"].contains( GAMETYPE ) ) intro.quick = true
    else if ( !["jugg","hotpotato","prophunt","bodyswap","gtfo","echo"].contains( GAMETYPE ) ) return
    thread PartyIntro_Run()
}

// "party_next <mode> <map>": sent just before a transition starts.
void function PartyIntro_NextCommand( array<string> args )
{
    if ( args.len() != 2 ) return
    intro.nextMode = args[0]
    intro.nextMap = args[1]
}

// ---------------------------------------------------------------- timing

// The animations' clock: real time, but at most a 30th of a second a frame, so a
// hitch (while the game is still loading in on a server) slows the animation for
// a moment instead of skipping part of it. Read it once a frame.
void function PartyIntro_ClockStart()
{
    intro.clock = 0.0
    intro.clockAt = Time()
}

float function PartyIntro_Clock()
{
    float now = Time()
    intro.clock += min( now - intro.clockAt, 1.0/30.0 )
    intro.clockAt = now
    return intro.clock
}

// The first frames in a game come in fits and starts while the client finishes
// loading: keep the loading screen's picture up until a run of frames is smooth
// (or a few seconds pass), so the animation starts on clean frames.
void function PartyIntro_WaitSmooth( array<IntroImage> card, array<var> texts, string map, string mode )
{
    float deadline = Time() + 4.0
    float last = Time()
    int smooth = 0
    while ( smooth < 20 && Time() < deadline )
    {
        PartyCard_Corner( card, texts, map, mode, 1.0 )
        WaitFrame()
        smooth = Time() - last < 0.05 ? smooth + 1 : 0
        last = Time()
    }
}

// ---------------------------------------------------------------- drawing

// The client has only 64 topologies: when there is no room the image comes back
// empty (topo null) with nothing left allocated, and PartyCard_TryCreate retries.
IntroImage function PartyIntro_Image( asset image, float w, float h, int sort, bool shadow, int shadowSort = INTRO_SORT+1 )
{
    IntroImage made
    made.w = w
    made.h = h
    try { made.topo = RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false ) }
    catch ( ex ) { made.topo = null; return made; }
    if ( shadow )
    {
        try { made.shadowTopo = RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false ) }
        catch ( ex )
        {
            RuiTopology_Destroy( made.topo )
            made.topo = null
            return made
        }
    }
    made.rui = RuiCreate( $"ui/basic_image.rpak", made.topo, RUI_DRAW_HUD, sort )
    if ( image != $"" ) RuiSetImage( made.rui, "basicImage", image )
    RuiSetFloat3( made.rui, "basicImageColor", <1,1,1> )
    RuiSetFloat( made.rui, "basicImageAlpha", 0.0 )
    if ( shadow )
    {
        made.shadow = RuiCreate( $"ui/basic_image.rpak", made.shadowTopo, RUI_DRAW_HUD, shadowSort )
        RuiSetImage( made.shadow, "basicImage", image )
        RuiSetFloat3( made.shadow, "basicImageColor", INTRO_SHADOW )
        RuiSetFloat( made.shadow, "basicImageAlpha", 0.0 )
    }
    return made
}

// Builds a card, or waits a frame and tries again while the client is out of
// topologies (ones freed this frame only come back on the next). False if it
// never fits; nothing is left allocated then.
bool function PartyCard_TryCreate( array<IntroImage> card, array<var> texts, int sort, asset line, float lineW, float lineH, string mapKey, string modeKey, bool iris = false )
{
    for ( int attempt = 0; attempt < 30; attempt++ )
    {
        PartyCard_Create( card, texts, sort, line, lineW, lineH, mapKey, modeKey, iris )
        bool complete = true
        foreach ( IntroImage image in card ) if ( image.topo == null ) complete = false
        if ( complete ) return true
        PartyCard_Destroy( card, texts )
        card.clear()
        texts.clear()
        if ( attempt == 0 ) printt( "[PartyIntro] no room for the card yet, retrying" )
        WaitFrame()
    }
    printt( "[PartyIntro] no room for the card, skipped" )
    return false
}

// Frees one of a card's images (once; a freed image is skipped).
void function PartyCard_Free( array<IntroImage> card, int index )
{
    if ( card[index].topo == null ) return
    RuiDestroyIfAlive( card[index].rui )
    RuiTopology_Destroy( card[index].topo )
    card[index].topo = null
    if ( card[index].shadow == null ) return
    RuiDestroyIfAlive( card[index].shadow )
    RuiTopology_Destroy( card[index].shadowTopo )
    card[index].shadow = null
}

// Places an image by its centre, in 1080p pixels relative to the screen centre,
// scaled by the slow push-in and by scale; its shadow (offset 7,9 at full size) scales along.
void function PartyIntro_Place( IntroImage image, float cx, float cy, float alpha, float scale = 1.0 )
{
    image.drawX=cx; image.drawY=cy; image.drawScale=scale; image.drawDegrees=0.0;
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0 * intro.zoom
    float w = image.w * s * scale
    float h = image.h * s * scale
    vector corner = <width*0.5+cx*s-w*0.5, height*0.5+cy*s-h*0.5, 0>
    RuiTopology_UpdatePos( image.topo, corner, <w,0,0>, <0,h,0> )
    RuiSetFloat( image.rui, "basicImageAlpha", clamp( alpha, 0.0, 1.0 ) )
    if ( image.shadow == null ) return
    RuiTopology_UpdatePos( image.shadowTopo, corner+<7.0*s*scale,9.0*s*scale,0>, <w,0,0>, <0,h,0> )
    RuiSetFloat( image.shadow, "basicImageAlpha", clamp( alpha, 0.0, 1.0 )*0.45 )
}

// As PartyIntro_Place, turned clockwise by degrees about the centre.
void function PartyIntro_PlaceTurned( IntroImage image, float cx, float cy, float alpha, float scale, float degrees )
{
    image.drawX=cx; image.drawY=cy; image.drawScale=scale; image.drawDegrees=degrees;
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0 * intro.zoom
    float w = image.w * s * scale
    float h = image.h * s * scale
    float a = degrees * PI / 180.0
    vector right = <w*cos( a ), w*sin( a ), 0>
    vector down = < -h*sin( a ), h*cos( a ), 0>
    vector centre = <width*0.5+cx*s, height*0.5+cy*s, 0>
    vector corner = centre - right*0.5 - down*0.5
    RuiTopology_UpdatePos( image.topo, corner, right, down )
    RuiSetFloat( image.rui, "basicImageAlpha", clamp( alpha, 0.0, 1.0 ) )
    if ( image.shadow == null ) return
    RuiTopology_UpdatePos( image.shadowTopo, corner+<7.0*s*scale,9.0*s*scale,0>, right, down )
    RuiSetFloat( image.shadow, "basicImageAlpha", clamp( alpha, 0.0, 1.0 )*0.45 )
}

float function PartyIntro_Ease( float u ) { u = clamp( u, 0.0, 1.0 ); return 1.0 - (1.0-u)*(1.0-u)*(1.0-u); }
float function PartyIntro_EaseBack( float u )
{
    u = clamp( u, 0.0, 1.0 )
    float v = u - 1.0
    return 1.0 + 2.0*v*v*v + v*v
}
float function PartyIntro_EaseIn( float u ) { u = clamp( u, 0.0, 1.0 ); return u*u*u; }
// Pulls back a little, then accelerates away.
float function PartyIntro_EaseInBack( float u )
{
    u = clamp( u, 0.0, 1.0 )
    return 2.70158*u*u*u - 1.70158*u*u
}
float function PartyIntro_EaseInOut( float u ) { u = clamp( u, 0.0, 1.0 ); return u*u*(3.0-2.0*u); }
float function PartyIntro_Lerp( float a, float b, float u ) { return a + (b-a)*u; }

void function PartyIntro_Sound( string sound )
{
    if ( sound == "" ) return
    entity player = GetLocalClientPlayer()
    if ( IsValid( player ) ) EmitSoundOnEntity( player, sound )
}

// The screen's width in 1080p pixels.
float function PartyIntro_Width()
{
    return GetScreenSize()[0] / ( GetScreenSize()[1] / 1080.0 )
}

// ---------------------------------------------------------------- the card

var function PartyCard_TextRui( int sort )
{
    var rui = CreateFullscreenRui( $"ui/cockpit_console_text_center.rpak", sort )
    RuiSetInt( rui, "maxLines", 1 )
    RuiSetInt( rui, "lineNum", 0 )
    RuiSetFloat( rui, "thicken", 0.25 )
    RuiSetFloat( rui, "msgFontSize", 50.0 )
    RuiSetFloat3( rui, "msgColor", <1,1,1> )
    RuiSetFloat( rui, "msgAlpha", 0.0 )
    return rui
}

// mapKey, modeKey: a map and a playlist name, for the name images. iris: also
// the pieces of the round reveal (PartyCard_IrisReveal).
void function PartyCard_Create( array<IntroImage> card, array<var> texts, int sort, asset line, float lineW, float lineH, string mapKey, string modeKey, bool iris = false )
{
    card.append( PartyIntro_Image( $"", 1.0, 1.0, sort-3, false ) )
    card.append( PartyIntro_Image( $"", 1.0, 1.0, sort-3, false ) )
    card.append( PartyIntro_Image( $"rui/ceaika/intro_gun", 576.0, 494.0, sort+5, true, sort+4 ) )
    card.append( PartyIntro_Image( $"rui/ceaika/intro_ceaikas", 532.0, 148.0, sort+2, true, sort+1 ) )
    card.append( PartyIntro_Image( $"rui/ceaika/intro_partypack", 581.0, 143.0, sort+7, true, sort+6 ) )
    // Muzzle mask: background-coloured panel over the row left of the muzzle, so
    // "Ceaika's" is hidden inside the gun and revealed as it slides out.
    card.append( PartyIntro_Image( $"", 1600.0, 200.0, sort+3, false ) )
    card.append( PartyIntro_Image( line, lineW, lineH, sort+7, true, sort+6 ) )
    card.append( PartyIntro_Image( $"rui/ceaika/flash", 256.0, 256.0, sort+9, false ) )
    card.append( PartyIntro_Image( $"", 1.0, 1.0, sort+8, false ) )
    // Names at their corner size; texts[0]/[1] stand in when there is no image.
    asset mapImage = PartyName_Image( mapKey )
    asset modeImage = PartyName_Image( modeKey )
    card.append( PartyIntro_Image( mapImage == $"" ? $"rui/ceaika/flash" : mapImage, PartyName_Aspect( mapKey )*CORNER_MAP_H, CORNER_MAP_H, sort+8, false ) )
    card.append( PartyIntro_Image( modeImage == $"" ? $"rui/ceaika/flash" : modeImage, PartyName_Aspect( modeKey )*CORNER_MODE_H, CORNER_MODE_H, sort+8, false ) )
    texts.append( mapImage == $"" ? PartyCard_TextRui( sort+8 ) : null )
    texts.append( modeImage == $"" ? PartyCard_TextRui( sort+8 ) : null )
    if ( !iris ) return
    card.append( PartyIntro_Image( $"rui/ceaika/iris", 1.0, 1.0, sort-3, false ) )
    card.append( PartyIntro_Image( $"", 1.0, 1.0, sort-3, false ) )
    card.append( PartyIntro_Image( $"", 1.0, 1.0, sort-3, false ) )
}

void function PartyCard_Destroy( array<IntroImage> card, array<var> texts, int keep = -1 )
{
    for ( int i = 0; i < card.len(); i++ ) if ( i != keep ) PartyCard_Free( card, i )
    for ( int i = 0; i < texts.len(); i++ )
    {
        if ( texts[i] != null ) RuiDestroyIfAlive( texts[i] )
        texts[i] = null
    }
}

void function PartyCard_Rect( IntroImage image, float x0, float y0, float x1, float y1, vector color, float alpha )
{
    RuiTopology_UpdatePos( image.topo, <x0,y0,0>, <max( 1.0, x1-x0 ),0,0>, <0,max( 1.0, y1-y0 ),0> )
    RuiSetFloat3( image.rui, "basicImageColor", color )
    RuiSetFloat( image.rui, "basicImageAlpha", x1 > x0 && y1 > y0 ? alpha : 0.0 )
}

// The orange, in two halves meeting along the muzzle's line. ox, oy shift the
// card (1080p pixels; it comes in from the top or the right, so it reaches
// past the other two edges to cover any overshoot). open: 0 closed, 1 open
// (the top half gone off the top, the bottom half off the bottom).
void function PartyCard_Back( array<IntroImage> card, float ox, float oy, float open, vector color, float alpha )
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    float left = ox*s
    float right = width + (ox+400.0)*s
    float seam = height*0.5 + (MUZZLE_Y+oy)*s
    float up = open*( seam + 40.0*s )
    float down = open*( height - seam + 40.0*s )
    PartyCard_Rect( card[CARD_TOP], left, (oy-400.0)*s - up, right, seam - up + 1.0, color, alpha )
    PartyCard_Rect( card[CARD_BOTTOM], left, seam + down, right, height + oy*s + down, color, alpha )
}

// A map or mode name, right-aligned at rightX (1080p pixels from the centre),
// height h (capital height); fallback text when there is no image.
void function PartyCard_Name( array<IntroImage> card, array<var> texts, int index, string text, float rightX, float cy, float h, float alpha )
{
    float scale = h / card[index].h
    var fallback = texts[index - CARD_MAP]
    if ( fallback == null )
    {
        PartyIntro_Place( card[index], rightX - card[index].w*scale*0.5, cy, alpha, scale )
        return
    }
    RuiSetString( fallback, "msgText", text )
    RuiSetFloat( fallback, "msgFontSize", h*1.3 )
    RuiSetFloat2( fallback, "msgPos", <( rightX - 250.0 )/PartyIntro_Width(), cy/1080.0, 0> )
    RuiSetFloat( fallback, "msgAlpha", clamp( alpha, 0.0, 1.0 ) )
}

// The names' heights (1080p pixels) as the loading screen shows them on this screen.
float function PartyCorner_MapH()
{
    float s = GetScreenSize()[1] / 1080.0
    return CORNER_MAP_H*min( 1.0, VGUI_MAX_TALL/( LOADING_MAP_FONT*s ) )
}
float function PartyCorner_ModeH()
{
    float s = GetScreenSize()[1] / 1080.0
    return CORNER_MODE_H*min( 1.0, VGUI_MAX_TALL/( LOADING_MODE_FONT*s ) )
}

// The corner layout's positions (centre-relative 1080p pixels).
float function PartyCorner_X( float fromLeft ) { return fromLeft - PartyIntro_Width()*0.5; }
float function PartyCorner_Y( float fromTop ) { return fromTop - 540.0; }
float function PartyCorner_Right() { return PartyIntro_Width()*0.5 - CORNER_NAMES_RIGHT; }

// The gun between the middle (u = 0) and the corner (u = 1), turned clockwise by degrees.
void function PartyCard_Gun( array<IntroImage> card, float u, float degrees, float alpha )
{
    PartyIntro_PlaceTurned( card[CARD_GUN], PartyIntro_Lerp( -281.0, PartyCorner_X( CORNER_GUN_X ), u ), PartyIntro_Lerp( -70.0, PartyCorner_Y( CORNER_GUN_Y ), u ), alpha, PartyIntro_Lerp( 1.0, CORNER_GUN_SCALE, u ), degrees )
}

// The corner gun's spin, as the loading screen's spinner turns.
float function PartyCard_Spin()
{
    return ( Time()*CORNER_SPIN ) % 360.0
}

// "Ceaika's Partypack" between the logo (u = 0) and the corner (u = 1).
void function PartyCard_Title( array<IntroImage> card, float u, float alpha )
{
    PartyIntro_Place( card[CARD_CEAIKAS], PartyIntro_Lerp( 303.0, PartyCorner_X( CORNER_CEAIKAS_X ), u ), PartyIntro_Lerp( -204.0, PartyCorner_Y( CORNER_CEAIKAS_Y ), u ), alpha, PartyIntro_Lerp( 1.0, CORNER_CEAIKAS_SCALE, u ) )
    PartyIntro_Place( card[CARD_PARTYPACK], PartyIntro_Lerp( 48.0, PartyCorner_X( CORNER_PARTYPACK_X ), u ), PartyIntro_Lerp( -35.0, PartyCorner_Y( CORNER_PARTYPACK_Y ), u ), alpha, PartyIntro_Lerp( 1.0, CORNER_PARTYPACK_SCALE, u ) )
}

// The loading screen's picture: the gun and the title in their corners, the
// map's name and the mode on the right. (The engine wipes the names and the tip
// the moment loading is done; the card puts the names back so they can leave
// in style. The tip it cannot: the engine picks it at random and never says which.)
void function PartyCard_Corner( array<IntroImage> card, array<var> texts, string map, string mode, float alpha )
{
    PartyCard_Back( card, 0.0, 0.0, 0.0, INTRO_ORANGE, 1.0 )
    PartyCard_Gun( card, 1.0, PartyCard_Spin(), 1.0 )
    PartyCard_CornerOut( card, texts, map, mode, 0.0 )
    PartyIntro_Place( card[CARD_MASK], 0.0, 0.0, 0.0 )
    RuiSetFloat3( card[CARD_MASK].rui, "basicImageColor", INTRO_ORANGE )
}

// The corner layout's words leaving, t seconds in: "Ceaika's Partypack" shoots
// off to the top left, the map's name off to the right and the mode after it.
// Each pulls back a little first.
void function PartyCard_CornerOut( array<IntroImage> card, array<var> texts, string map, string mode, float t )
{
    float width = PartyIntro_Width()
    float title = PartyIntro_EaseInBack( t/0.45 )
    float mapOut = PartyIntro_EaseInBack( (t-0.06)/0.45 )
    float modeOut = PartyIntro_EaseInBack( (t-0.14)/0.45 )
    float tx = -( width*0.5 )*title
    float ty = -260.0*title
    PartyIntro_Place( card[CARD_CEAIKAS], PartyCorner_X( CORNER_CEAIKAS_X ) + tx, PartyCorner_Y( CORNER_CEAIKAS_Y ) + ty, 1.0, CORNER_CEAIKAS_SCALE )
    PartyIntro_Place( card[CARD_PARTYPACK], PartyCorner_X( CORNER_PARTYPACK_X ) + tx*1.08, PartyCorner_Y( CORNER_PARTYPACK_Y ) + ty*1.08, 1.0, CORNER_PARTYPACK_SCALE )
    PartyCard_Name( card, texts, CARD_MAP, map, PartyCorner_Right() + ( width + 200.0 )*mapOut, PartyCorner_Y( CORNER_MAP_Y ), PartyCorner_MapH(), 1.0 )
    PartyCard_Name( card, texts, CARD_MODE, mode, PartyCorner_Right() + ( width*0.6 + 200.0 )*modeOut, PartyCorner_Y( CORNER_MODE_Y ), PartyCorner_ModeH(), 1.0 )
}

// The logo at time t of the intro's build-up: "Ceaika's" comes out of the
// barrel, "Partypack" flies in and slams into the gun. The gun slides in from
// the left first, unless gunInPlace (then the caller has brought it back).
// dy moves the whole block (1080p pixels).
void function PartyIntro_DrawLogo( array<IntroImage> card, float t, float dy, float out, bool gunInPlace = false )
{
    float width = PartyIntro_Width()
    // The impact shakes the logo block for a moment.
    float decay = t < INTRO_IMPACT ? 0.0 : max( 0.0, 1.0 - (t-INTRO_IMPACT)/0.35 )
    float shakeX = 7.0*decay*sin( t*71.0 )
    float shakeY = 5.0*decay*cos( t*53.0 ) + dy

    float gunStart = -width*0.5 - 330.0
    float gunX = gunInPlace ? -281.0 : gunStart + (-281.0-gunStart)*PartyIntro_EaseBack( (t-0.9)/1.1 )
    float gunDrawX = gunX + shakeX - 8.0*decay
    PartyIntro_Place( card[CARD_GUN], gunDrawX, -70.0 + shakeY, gunInPlace || t >= 0.9 ? out : 0.0 )

    // "Ceaika's" starts hidden inside the gun and is revealed as it slides out
    // past the muzzle: the mask covers its row up to the gun's front edge.
    float muzzle = gunDrawX + 288.0 - 6.0
    PartyIntro_Place( card[CARD_MASK], muzzle - 800.0, -204.0 + shakeY, t < 0.9 ? 0.0 : out )
    float slide = PartyIntro_Ease( (t-1.8)/1.3 )
    float hiddenX = -281.0 + 288.0 - 6.0 - 266.0 - 12.0
    PartyIntro_Place( card[CARD_CEAIKAS], hiddenX + (303.0-hiddenX)*slide + shakeX, -204.0 + shakeY, t < 1.8 ? 0.0 : out )

    // "Partypack" flies in from the right, speeding up into the gun, then bounces and settles.
    float partyX = 48.0
    float partyStart = width*0.5 + 330.0
    float x = partyStart
    if ( t >= 2.9 && t < INTRO_IMPACT ) { float u = (t-2.9)/(INTRO_IMPACT-2.9); x = partyStart + (partyX-partyStart)*u*u; }
    else if ( t >= INTRO_IMPACT ) { float u = clamp( (t-INTRO_IMPACT)/0.55, 0.0, 1.0 ); x = partyX + 38.0*sin( u*PI )*(1.0-u); }
    PartyIntro_Place( card[CARD_PARTYPACK], x + shakeX, -35.0 + shakeY, t < 2.9 ? 0.0 : out )
}

// Arriving: from the loading screen's last picture back to the full logo, at
// time t of the intro's timeline. The title fades, the gun grows back to the
// middle, then the logo builds up around it.
void function PartyCard_Arrival( array<IntroImage> card, array<var> texts, string map, string mode, float t, float spinFrom )
{
    // The words leave first, then the gun comes home.
    float back = PartyIntro_EaseInOut( (t-0.45)/1.3 )
    float flash = t < INTRO_IMPACT ? 0.0 : max( 0.0, 1.0 - (t-INTRO_IMPACT)/0.25 )
    vector color = INTRO_ORANGE + (INTRO_FLASH-INTRO_ORANGE)*flash
    PartyCard_Back( card, 0.0, 0.0, 0.0, color, 1.0 )
    RuiSetFloat3( card[CARD_MASK].rui, "basicImageColor", color )
    if ( t < 1.8 )
    {
        // The words slide off the screen; the gun comes home, its spin
        // winding down to upright on the way.
        PartyCard_CornerOut( card, texts, map, mode, t )
        float spin = spinFrom + CORNER_SPIN*min( t, 0.45 )
        float upright = ceil( ( spin + 90.0 )/360.0 )*360.0
        PartyCard_Gun( card, 1.0 - back, spin + ( upright - spin )*back, 1.0 )
        PartyIntro_Place( card[CARD_MASK], 0.0, 0.0, 0.0 )
        return
    }
    PartyCard_Name( card, texts, CARD_MAP, map, 0.0, 0.0, CORNER_MAP_H, 0.0 )
    PartyCard_Name( card, texts, CARD_MODE, mode, 0.0, 0.0, CORNER_MODE_H, 0.0 )
    PartyIntro_DrawLogo( card, t, 0.0, 1.0, true )
}

// The reveal at f seconds after it is called: the title goes, the gun fires a
// white line out of the barrel and slides away to the left as if we follow the
// bullet, then the card opens along the line. Returns false once it is open.
bool function PartyCard_Reveal( array<IntroImage> card, float f )
{
    float width = PartyIntro_Width()
    float s = GetScreenSize()[1] / 1080.0
    PartyIntro_Place( card[CARD_MASK], 0.0, 0.0, 0.0 )
    // The title fades and shrinks a little.
    float gone = 1.0 - clamp( f/FIRE_AT, 0.0, 1.0 )
    PartyIntro_Place( card[CARD_CEAIKAS], 303.0, -204.0, gone, 0.9 + 0.1*gone )
    PartyIntro_Place( card[CARD_PARTYPACK], 48.0, -35.0, gone, 0.9 + 0.1*gone )
    // The shot: a kick back, then the gun slides off to the left.
    float shot = f - FIRE_AT
    float kick = shot < 0.0 ? 0.0 : sin( clamp( shot/0.2, 0.0, 1.0 )*PI )*( 1.0 - clamp( shot/0.2, 0.0, 1.0 ) )
    float slide = ( width*0.5 + 650.0 )*PartyIntro_EaseIn( (f-FIRE_SLIDE)/(FIRE_OPEN-FIRE_SLIDE) )
    float gunX = -281.0 - 18.0*kick - slide
    PartyIntro_Place( card[CARD_GUN], gunX, -70.0, 1.0 )
    float muzzle = gunX + 288.0
    // The flash pops at the muzzle and fades.
    float pop = shot < 0.0 ? 0.0 : clamp( shot/0.06, 0.0, 1.0 )
    float flash = shot < 0.0 ? 0.0 : 1.0 - clamp( (shot-0.04)/0.18, 0.0, 1.0 )
    PartyIntro_Place( card[CARD_FLASH], muzzle + 26.0, MUZZLE_Y, pop*flash, 0.4 + 0.6*pop )
    // The line: from the muzzle to the right edge in a blink, then it stretches
    // left behind the gun; it brightens and fades as the card opens.
    float open = 0.0
    if ( shot >= 0.0 )
    {
        float reach = muzzle + ( width*0.5 + 60.0 - muzzle )*PartyIntro_Ease( shot/0.1 )
        float opening = clamp( (f-FIRE_OPEN)/(FIRE_DONE-FIRE_OPEN), 0.0, 1.0 )
        open = PartyIntro_EaseInOut( opening )
        float thick = 16.0 + 20.0*sin( clamp( opening/0.4, 0.0, 1.0 )*PI )
        float x0 = GetScreenSize()[0]*0.5 + muzzle*s
        float x1 = GetScreenSize()[0]*0.5 + reach*s
        float y = GetScreenSize()[1]*0.5 + MUZZLE_Y*s
        PartyCard_Rect( card[CARD_BULLET], max( 0.0, x0 ), y - thick*0.5*s, x1, y + thick*0.5*s, <1,1,1>, 1.0 - clamp( (opening-0.25)/0.35, 0.0, 1.0 ) )
    }
    PartyCard_Back( card, 0.0, 0.0, open, INTRO_ORANGE, 1.0 )
    return f < FIRE_DONE
}

// The orange with a round hole at the muzzle, hole (1080p pixels) across.
void function PartyCard_Hole( array<IntroImage> card, float hole )
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    float d = hole*s
    float hx = width*0.5 + MUZZLE_X*s
    float hy = height*0.5 + MUZZLE_Y*s
    float x0 = hx - d*0.5
    float x1 = hx + d*0.5
    float y0 = hy - d*0.5
    float y1 = hy + d*0.5
    // The pieces overlap by a pixel: edge to edge, their seams show as faint lines.
    PartyCard_Rect( card[CARD_TOP], -40.0, -40.0, width + 40.0, y0 + 1.0, INTRO_ORANGE, 1.0 )
    PartyCard_Rect( card[CARD_BOTTOM], -40.0, y1 - 1.0, width + 40.0, height + 40.0, INTRO_ORANGE, 1.0 )
    PartyCard_Rect( card[CARD_IRIS_LEFT], -40.0, y0, x0 + 1.0, y1, INTRO_ORANGE, 1.0 )
    PartyCard_Rect( card[CARD_IRIS_RIGHT], x1 - 1.0, y0, width + 40.0, y1, INTRO_ORANGE, 1.0 )
    PartyCard_Rect( card[CARD_IRIS], x0, y0, x1, y1, INTRO_ORANGE, d > 1.0 ? 1.0 : 0.0 )
}

// The lobby's reveal at f seconds after it is called: the gun cocks back,
// fires (a flash and a kick), a round hole opens from the muzzle until it
// fills the screen, "Ceaika's" and "Partypack" are blown away from it and the
// gun recoils out. Returns false once the lobby is fully revealed.
bool function PartyCard_IrisReveal( array<IntroImage> card, float f )
{
    PartyIntro_Place( card[CARD_MASK], 0.0, 0.0, 0.0 )
    float cock = PartyIntro_EaseInOut( f/FIRE_AT )
    float shot = f - FIRE_AT
    // Big enough to clear the far corner of the screen from the muzzle.
    float reach = 2.0*sqrt( pow( PartyIntro_Width()*0.5 + fabs( MUZZLE_X ), 2 ) + pow( 540.0 + fabs( MUZZLE_Y ), 2 ) ) + 80.0
    PartyCard_Hole( card, shot < 0.0 ? 0.0 : reach*pow( clamp( shot/IRIS_OPEN, 0.0, 1.0 ), 1.7 ) )
    float shake = shot < 0.0 ? 0.0 : max( 0.0, 1.0 - shot/0.25 )
    float sx = 9.0*shake*sin( f*83.0 )
    float sy = 7.0*shake*cos( f*61.0 )
    float blow = shot < 0.0 ? 0.0 : PartyIntro_Ease( shot/0.45 )
    float gone = shot < 0.0 ? 1.0 : 1.0 - clamp( (shot-0.1)/0.3, 0.0, 1.0 )
    // The gun eases back as it cocks, then recoils hard off to the left.
    float gunX = -281.0 - 22.0*cock - 260.0*blow + sx
    PartyIntro_Place( card[CARD_GUN], gunX, -70.0 + 40.0*blow + sy, gone )
    // "Ceaika's" and "Partypack" are blown out, away from the muzzle, growing.
    PartyIntro_Place( card[CARD_CEAIKAS], 303.0 + 320.0*blow + sx, -204.0 - 120.0*blow + sy, gone, 1.0 + 0.35*blow )
    PartyIntro_Place( card[CARD_PARTYPACK], 48.0 + 380.0*blow + sx, -35.0 + 140.0*blow + sy, gone, 1.0 + 0.35*blow )
    // The flash pops at the muzzle and fades.
    float pop = shot < 0.0 ? 0.0 : clamp( shot/0.08, 0.0, 1.0 )
    float fade = shot < 0.0 ? 0.0 : 1.0 - clamp( (shot-0.05)/0.22, 0.0, 1.0 )
    PartyIntro_Place( card[CARD_FLASH], gunX + 288.0 + 26.0, MUZZLE_Y + sy, pop*fade, 0.6 + 1.2*pop )
    return shot < IRIS_OPEN + 0.05
}

// The names the loading screen shows: the playlist's name and the map's (as text).
string function PartyCard_ModeName( string playlist )
{
    if ( playlist == "" ) return ""
    return Localize( GetPlaylistVarOrUseValue( playlist, "name", "#PL_" + playlist ) ).toupper()
}

string function PartyCard_MapName( string map )
{
    if ( map == "" ) return ""
    return Localize( GetMapDisplayName( map ) ).toupper()
}

// ---------------------------------------------------------------- the match intro

void function PartyIntro_Run()
{
    if(intro.hushPlaying) return
    // Only a fresh match: someone joining mid-match goes straight in.
    if ( GetGameState() >= eGameState.Playing ) return
    if(GAMETYPE=="echo") intro.hushPlaying=true
    printt( "[PartyIntro] playing" )
    string mapKey = GetMapName()
    string modeKey = GetCurrentPlaylistName()
    array<IntroImage> card
    array<var> texts
    OnThreadEnd( function() : ( card, texts )
    {
        PartyCard_Destroy( card, texts )
        intro.hushPlaying=false
    } )
    if ( !PartyCard_TryCreate( card, texts, INTRO_SORT, $"rui/ceaika/intro_presents", 573.0, 140.0, mapKey, modeKey ) ) return
    string map = PartyCard_MapName( mapKey )
    string mode = PartyCard_ModeName( modeKey )
    // The loading screen's picture stays up until the client is ready.
    while ( !IsValid( GetLocalClientPlayer() ) )
    {
        PartyCard_Corner( card, texts, map, mode, 1.0 )
        WaitFrame()
    }
    PartyIntro_WaitSmooth( card, texts, map, mode )
    if ( GetGameState() >= eGameState.Playing ) return
    intro.started = Time()
    intro.spinFrom = PartyCard_Spin()
    // The clip has its own fade-out and plays to the end (about 11 s), a little
    // past the hand-off into the game.
    entity player = GetLocalClientPlayer()
    PartyIntro_StopMusic(0.0)
    intro.musicEvent=GAMETYPE=="echo" ? HUSH_GLITCH_MUSIC : INTRO_MUSIC
    if ( IsValid( player ) ) { EmitSoundOnEntity( player, intro.musicEvent ); intro.musicPlaying = true; }
    if(GAMETYPE=="echo") waitthread PartyHushGlitch_Sequence(card,texts,map,mode)
    else waitthread PartyIntro_Sequence( card, texts, map, mode )
    // A client holds only 64 RUI topologies (modes' HUDs and Prop Hunt's
    // boundary walls need theirs): keep just "presents..." from here on.
    PartyCard_Destroy( card, texts, CARD_LINE )
    waitthread PartyIntro_Presents( card )
}

void function PartyIntro_Sequence( array<IntroImage> card, array<var> texts, string map, string mode )
{
    array<string> cues = ["Menu_GameSummary_ScreenSlideIn", "UI_InGame_FD_InfoCardSlideIn", "UI_InGame_FD_MetaUpgradeTextAppear", "Menu_GameSummary_ScreenSlideIn", "Menu_LoadOut_Weapon_Select", "UI_Menu_Item_Purchased_Stinger"]
    array<float> cueTimes = [0.05, 0.45, 1.8, 2.9, INTRO_IMPACT, 3.9]
    int nextCue = 0
    float fireAt = -1.0
    bool shot = false
    PartyIntro_ClockStart()
    while ( true )
    {
        float t = PartyIntro_Clock()
        while ( nextCue < cues.len() && t >= cueTimes[nextCue] ) { PartyIntro_Sound( cues[nextCue] ); nextCue++; }
        // Fire once the logo has built up and the match has started (stock
        // modes: as soon as the gun is back).
        if ( fireAt < 0.0 && ( t >= INTRO_HOLD || ( intro.quick && t >= 1.8 ) ) && ( GetGameState() >= eGameState.Playing || t >= INTRO_MAX_HOLD ) )
        {
            fireAt = t
        }
        // A slow push-in once the gun is home.
        if ( fireAt < 0.0 ) intro.zoom = 1.0 + 0.03*PartyIntro_Ease( (t-1.8)/4.0 )
        // "presents..." rises in after the slam and stays (over the game too).
        float appear = PartyIntro_Ease( (t-3.9)/0.8 )
        PartyIntro_Place( card[CARD_LINE], 0.0, CARD_LINE_Y + 18.0*(1.0-appear), t < 3.9 ? 0.0 : appear )
        if ( fireAt >= 0.0 )
        {
            // The names are long gone; the reveal draws the rest.
            PartyCard_Name( card, texts, CARD_MAP, map, 0.0, 0.0, CORNER_MAP_H, 0.0 )
            PartyCard_Name( card, texts, CARD_MODE, mode, 0.0, 0.0, CORNER_MODE_H, 0.0 )
            if ( !shot && t - fireAt >= FIRE_AT ) { shot = true; PartyIntro_Sound( FIRE_SOUND ); }
            if ( !PartyCard_Reveal( card, t - fireAt ) ) return
        }
        else PartyCard_Arrival( card, texts, map, mode, t, intro.spinFrom )
        WaitFrame()
    }
}

// "presents..." stays over the game until a second after the mode's title
// banner appears (or 8 s if the mode shows none, e.g. Prop Hunt waiting for players).
void function PartyIntro_Presents( array<IntroImage> card )
{
    printt( "[PartyIntro] into the game" )
    float until = Time() + 8.0
    if ( intro.quick ) until = Time()
    while ( Time() < until )
    {
        if ( PartyUI_BannerShowing() ) until = min( until, Time() + 1.0 )
        WaitFrame()
    }
    float fadeStart = Time()
    while ( Time() < fadeStart + 0.5 )
    {
        PartyIntro_Place( card[CARD_LINE], 0.0, CARD_LINE_Y, 1.0 - (Time()-fadeStart)/0.5 )
        WaitFrame()
    }
    printt( "[PartyIntro] done" )
}

// Fades the theme out (0 stops it at once). Safe to call more than once.
void function PartyIntro_StopMusic( float fade )
{
    if ( !intro.musicPlaying ) return
    intro.musicPlaying = false
    entity player = GetLocalClientPlayer()
    if ( !IsValid( player ) ) return
    if ( fade > 0.0 ) FadeOutSoundOnEntity( player, intro.musicEvent, fade )
    else StopSoundOnEntity( player, intro.musicEvent )
}

// ---------------------------------------------------------------- transitions between matches
// 0: end of a match, the orange drops in from above with "redirecting to lobby...".
// 1: the lobby is launching, the orange sweeps in from the right with
//    "starting a new game..." and the mode's name.
// 0 and 1 build the logo up, the line under it blinks, then the card settles
// into the loading screen's layout: the gun shrinks into the bottom-left
// corner, "Ceaika's Partypack" lines up in the top-left corner and the map and
// the mode fade in at the top right (the mode's name slides up there). They stay
// up until the map changes (the client scripts are torn down then).
// 3: the match is over, show everyone the scoreboard until the curtain drops.
// Arriving in the lobby (PartyTransition_Arrive): the match intro's arrival and
// reveal, faster.
const float TRANSITION_SPEED = 1.6 // the logo animation, against the intro's pace
const float TRANSITION_LOGO = 0.6  // when the logo animation starts
const float TRANSITION_CORNER = 3.0 // the card settles into the loading screen's layout (the server changes map at 4.6; clients start late)
struct
{
    bool active = false
    bool scoreboard = false
} transition

void function PartyTransition( int kind, int mode )
{
    if ( kind == 3 ) { thread PartyTransition_Scoreboard(); return; }
    if ( transition.active ) return
    thread PartyTransition_Show( kind, mode )
}

// Keeps the scoreboard open (players can still close it) until the curtain covers it.
void function PartyTransition_Scoreboard()
{
    transition.scoreboard = true
    ShowScoreboard()
    printt( "[PartyIntro] scoreboard" )
}

// Same order as the lobby's modes.
string function PartyTransition_ModeKey( int mode )
{
    array<string> keys = ["jugg","hotpotato","prophunt","bodyswap","ffa","hidden","chamber","gg","inf","gtfo","echo"]
    return mode >= 0 && mode < keys.len() ? keys[mode] : ""
}

// Time on the intro's timeline for transition time t.
float function PartyTransition_LogoTime( float t )
{
    return 0.9 + ( t - TRANSITION_LOGO ) * TRANSITION_SPEED
}

// The line under the logo: rises in, then blinks three times and stays.
float function PartyTransition_Blink( float since )
{
    if ( since < 0.0 ) return 0.0
    float appear = PartyIntro_Ease( since/0.35 )
    float blink = since - 0.6
    if ( blink >= 0.0 && blink < 0.9 && int( blink / 0.15 ) % 2 == 0 ) return 0.12
    return appear
}

// Arriving in the lobby: the loading screen's picture until the lobby is
// ready, then the arrival at the transitions' pace and the round reveal.
void function PartyTransition_Arrive()
{
    transition.active = true
    intro.zoom = 1.0
    string mapKey = GetMapName()
    string modeKey = GetCurrentPlaylistName()
    array<IntroImage> card
    array<var> texts
    OnThreadEnd( function() : ( card, texts )
    {
        PartyCard_Destroy( card, texts )
        transition.active = false
    } )
    if ( !PartyCard_TryCreate( card, texts, INTRO_SORT+20, $"rui/ceaika/intro_presents", 573.0, 140.0, mapKey, modeKey, true ) ) return
    string map = PartyCard_MapName( mapKey )
    string mode = PartyCard_ModeName( modeKey )
    printt( "[PartyIntro] arrive: " + mode + " / " + map )
    PartyCard_Hole( card, 0.0 )
    array<string> cues = ["Menu_GameSummary_ScreenSlideIn", "UI_InGame_FD_InfoCardSlideIn", "UI_InGame_FD_MetaUpgradeTextAppear", "Menu_GameSummary_ScreenSlideIn", "Menu_LoadOut_Weapon_Select"]
    array<float> cueTimes = [0.05, 0.45, 1.8, 2.9, INTRO_IMPACT]
    int nextCue = 0
    float started = Time()
    float goAt = -1.0
    float fireAt = -1.0
    bool shot = false
    while ( true )
    {
        if ( goAt < 0.0 && IsValid( GetLocalClientPlayer() ) && ( GetGameState() >= eGameState.Playing || Time() - started > 20.0 ) )
        {
            PartyIntro_WaitSmooth( card, texts, map, mode )
            goAt = Time()
            intro.spinFrom = PartyCard_Spin()
            PartyIntro_ClockStart()
        }
        if ( goAt < 0.0 )
        {
            PartyCard_Corner( card, texts, map, mode, 1.0 )
            WaitFrame()
            continue
        }
        float clock = PartyIntro_Clock()
        float t = clock*TRANSITION_SPEED
        while ( nextCue < cues.len() && t >= cueTimes[nextCue] ) { PartyIntro_Sound( cues[nextCue] ); nextCue++; }
        if ( fireAt < 0.0 && t >= INTRO_READY ) fireAt = clock
        if ( fireAt >= 0.0 )
        {
            PartyCard_Name( card, texts, CARD_MAP, map, 0.0, 0.0, CORNER_MAP_H, 0.0 )
            PartyCard_Name( card, texts, CARD_MODE, mode, 0.0, 0.0, CORNER_MODE_H, 0.0 )
            if ( !shot && clock - fireAt >= FIRE_AT ) { shot = true; PartyIntro_Sound( FIRE_SOUND ); }
            if ( !PartyCard_IrisReveal( card, clock - fireAt ) ) return
        }
        else PartyCard_Arrival( card, texts, map, mode, t, intro.spinFrom )
        WaitFrame()
    }
}

void function PartyTransition_Show( int kind, int mode )
{
    // The lobby's holograms hold a good share of the client's 64 planes: free
    // them first, or the card cannot be made and there is no transition.
    // They only come back on the next frame.
    PartyVoteBoards_Release()
    PartyCredits_Release()
    PartyStatue_Release()
    transition.active = true
    intro.zoom = 1.0
    bool starting = kind == 1
    // Where the map change goes.
    string modeKey = intro.nextMode != "" ? intro.nextMode : ( starting ? PartyTransition_ModeKey( mode ) : "partylobby" )
    string mapKey = intro.nextMap != "" ? intro.nextMap : ( starting ? "" : "mp_coliseum" )
    array<IntroImage> card
    array<var> texts
    OnThreadEnd( function() : ( card, texts )
    {
        PartyCard_Destroy( card, texts )
        transition.active = false
    } )
    WaitFrame()
    if ( !PartyCard_TryCreate( card, texts, INTRO_SORT+20, starting ? $"rui/ceaika/intro_starting" : $"rui/ceaika/intro_redirecting", starting ? 914.0 : 879.0, 110.0, mapKey, modeKey ) ) return
    string map = PartyCard_MapName( mapKey )
    string toMode = PartyCard_ModeName( modeKey )
    printt( "[PartyIntro] transition " + kind + " to " + toMode + " / " + map )
    PartyIntro_Sound( kind == 0 ? "Menu_GameSummary_ScreenSlideIn" : "UI_InGame_HalftimeText_Enter" )
    // The intro's sound cues, at the transition's pace (no music).
    array<string> cues = ["UI_InGame_FD_InfoCardSlideIn", "UI_InGame_FD_MetaUpgradeTextAppear", "Menu_GameSummary_ScreenSlideIn", "Menu_LoadOut_Weapon_Select", "UI_Menu_Item_Purchased_Stinger"]
    array<float> cueTimes = [0.9, 1.8, 2.9, INTRO_IMPACT, 3.9]
    int nextCue = 0
    float phraseAt = TRANSITION_LOGO + ( 3.9 - 0.9 ) / TRANSITION_SPEED
    bool cornerSound = false
    float spinBase = -1.0
    float started = Time()
    while ( true )
    {
        float t = Time() - started
        float width = PartyIntro_Width()
        float logo = PartyTransition_LogoTime( t )
        while ( nextCue < cues.len() && logo >= cueTimes[nextCue] ) { PartyIntro_Sound( cues[nextCue] ); nextCue++; }
        // The curtain comes in with a little overshoot: from above at the end of
        // a match, from the right when the lobby launches a mode.
        float drop = 0.0
        float sweep = 0.0
        if ( kind == 0 ) drop = -1100.0*( 1.0 - PartyIntro_EaseBack( t/0.65 ) )
        else sweep = width*( 1.0 - PartyIntro_EaseBack( t/0.55 ) )
        // The scoreboard draws above the curtain: close it as the curtain drops.
        if ( transition.scoreboard && kind == 0 ) { transition.scoreboard = false; HideScoreboard(); }
        float flash = logo < INTRO_IMPACT ? 0.0 : max( 0.0, 1.0 - (logo-INTRO_IMPACT)/0.25 )
        vector color = INTRO_ORANGE + (INTRO_FLASH-INTRO_ORANGE)*flash
        PartyCard_Back( card, sweep, drop, 0.0, color, 1.0 )
        RuiSetFloat3( card[CARD_MASK].rui, "basicImageColor", color )
        // Settling into the loading screen's layout.
        float m = t - TRANSITION_CORNER
        if ( m >= 0.0 && !cornerSound ) { cornerSound = true; PartyIntro_Sound( "Menu_GameSummary_ScreenSlideIn" ); }
        float titleU = PartyIntro_EaseInOut( m/0.65 )
        float gunU = PartyIntro_EaseInOut( (m-0.12)/0.68 )
        if ( m < 0.0 ) PartyIntro_DrawLogo( card, logo, drop, 1.0 )
        else
        {
            PartyIntro_Place( card[CARD_MASK], 0.0, 0.0, 0.0 )
            PartyCard_Title( card, titleU, 1.0 )
            // It starts spinning as it shrinks, ending in step with the corner's spin.
            if ( spinBase < 0.0 ) spinBase = PartyCard_Spin()
            PartyCard_Gun( card, gunU, ( spinBase + CORNER_SPIN*m )*gunU, 1.0 )
        }
        // The line rises in and blinks, then drops away as the card settles.
        float away = clamp( m/0.25, 0.0, 1.0 )
        float words = PartyTransition_Blink( t - phraseAt ) * ( 1.0 - away )
        float rise = 18.0*( 1.0 - PartyIntro_Ease( (t-phraseAt)/0.35 ) ) + 24.0*away
        PartyIntro_Place( card[CARD_LINE], 0.0, CARD_LINE_Y + rise + drop, words )
        // The names: starting a mode its name shows under the line and slides up
        // into the corner; the map (and the lobby's name) fade in there.
        float namesIn = clamp( (m-0.35)/0.4, 0.0, 1.0 )
        float right = PartyCorner_Right()
        if ( starting )
        {
            float modeIn = clamp( (t-phraseAt-0.25)/0.3, 0.0, 1.0 )
            float startW = card[CARD_MODE].w*CARD_STARTING_MODE_H/CORNER_MODE_H
            float h = PartyIntro_Lerp( CARD_STARTING_MODE_H, PartyCorner_ModeH(), titleU )
            float rx = PartyIntro_Lerp( startW*0.5, right, titleU )
            float cy = PartyIntro_Lerp( CARD_STARTING_MODE_Y + drop, PartyCorner_Y( CORNER_MODE_Y ), titleU )
            PartyCard_Name( card, texts, CARD_MODE, toMode, rx, cy, h, modeIn )
        }
        else PartyCard_Name( card, texts, CARD_MODE, toMode, right, PartyCorner_Y( CORNER_MODE_Y ), PartyCorner_ModeH(), namesIn )
        PartyCard_Name( card, texts, CARD_MAP, map, right, PartyCorner_Y( CORNER_MAP_Y ), PartyCorner_MapH(), mapKey == "" ? 0.0 : namesIn )
        WaitFrame()
    }
}

// The original logo/reveal choreography with a Hush-only digital breakdown.
const int HUSH_GLITCH_FIRST = 11
const int HUSH_GLITCH_BLOCKS = 10
const int HUSH_GLITCH_GHOST = 21
const int HUSH_GLITCH_TEAR = 23

float function PartyHushGlitch_Burst(float t)
{
    array<float> beats=[2.46,3.60,4.17,4.72,5.08,5.43]
    array<float> lengths=[0.32,0.38,0.34,0.32,0.12,0.20]
    float result=0.0
    for(int i=0;i<beats.len();i++)
    {
        float age=t-beats[i]
        if(age>=0.0 && age<lengths[i]) result=max(result,min(1.0,min(age/0.025,(lengths[i]-age)/0.035)))
    }
    return result
}
bool function PartyHushGlitch_Extras(array<IntroImage> card)
{
    for(int i=0;i<HUSH_GLITCH_BLOCKS;i++)
        card.append(PartyIntro_Image($"",1.0,1.0,INTRO_SORT+12,false))
    card.append(PartyIntro_Image($"rui/ceaika/intro_ceaikas",532.0,148.0,INTRO_SORT+11,false))
    card.append(PartyIntro_Image($"rui/ceaika/intro_partypack",581.0,143.0,INTRO_SORT+11,false))
    foreach(asset image in [$"rui/ceaika/hush_tear_gun",$"rui/ceaika/hush_tear_ceaikas",$"rui/ceaika/hush_tear_partypack"])
    {
        card.append(PartyIntro_Image($"",1.0,1.0,INTRO_SORT+13,false))
        card.append(PartyIntro_Image(image,1.0,1.0,INTRO_SORT+14,false))
    }
    bool complete=true
    for(int i=HUSH_GLITCH_FIRST;i<card.len();i++) if(card[i].topo==null) complete=false
    if(!complete)
    {
        for(int i=HUSH_GLITCH_FIRST;i<card.len();i++) PartyCard_Free(card,i)
        print("[HushGlitch] overlay planes unavailable; keeping palette and logo transforms")
    }
    return complete
}
void function PartyHushGlitch_Transform(IntroImage image,float dx,float dy,bool mirror,bool upside,float stretchX=1.0,float stretchY=1.0)
{
    float s=GetScreenSize()[1]/1080.0*intro.zoom
    float w=image.w*s*image.drawScale*stretchX
    float h=image.h*s*image.drawScale*stretchY
    float angle=image.drawDegrees*PI/180.0
    vector right=<w*cos(angle),w*sin(angle),0>*(mirror ? -1.0 : 1.0)
    vector down=< -h*sin(angle),h*cos(angle),0>*(upside ? -1.0 : 1.0)
    vector center=<GetScreenSize()[0]*0.5+(image.drawX+dx)*s,GetScreenSize()[1]*0.5+(image.drawY+dy)*s,0>
    vector corner=center-right*0.5-down*0.5
    RuiTopology_UpdatePos(image.topo,corner,right,down)
    if(image.shadow!=null) RuiTopology_UpdatePos(image.shadowTopo,corner+<5*s,6*s,0>,right,down)
}
void function PartyHushGlitch_Draw(array<IntroImage> card,float t,bool extras)
{
    float gray=PartyIntro_EaseInOut((t-1.65)/1.90)
    float dark=PartyIntro_EaseInOut((t-3.1)/1.9)
    float burst=PartyHushGlitch_Burst(t)
    float neutral=PartyIntro_Lerp(0.16,0.035,dark)
    vector background=INTRO_ORANGE*(1.0-gray)+<neutral,neutral,neutral>*gray
    RuiSetFloat3(card[CARD_TOP].rui,"basicImageColor",background)
    RuiSetFloat3(card[CARD_BOTTOM].rui,"basicImageColor",background)
    RuiSetFloat3(card[CARD_MASK].rui,"basicImageColor",background)
    foreach(int index in [CARD_GUN,CARD_CEAIKAS,CARD_PARTYPACK,CARD_LINE])
    {
        float shade=PartyIntro_Lerp(1.0,index==CARD_GUN ? 0.55 : 0.78,gray)
        RuiSetFloat3(card[index].rui,"basicImageColor",<shade,shade,shade>)
        if(card[index].shadow!=null)
            RuiSetFloat3(card[index].shadow,"basicImageColor",INTRO_SHADOW*(1.0-gray)+<0.004,0.004,0.004>*gray)
    }
    RuiSetFloat3(card[CARD_FLASH].rui,"basicImageColor",<0.6,0.6,0.6>)

    // Brief readable flips, with the original frame restored by the base draw.
    if(burst>0.12 && t>=3.6 && t<5.2)
    {
        bool inverted=t>=4.17 && t<4.51
        bool backwards=t>=4.72 && t<5.04
        float step=floor(t*10.0)
        float dx=(sin(step*2.8)>0.0 ? 1.0 : -1.0)*(34.0+55.0*burst)
        PartyHushGlitch_Transform(card[CARD_CEAIKAS],dx,-5.0*burst,backwards || inverted,backwards || inverted)
        PartyHushGlitch_Transform(card[CARD_PARTYPACK],-dx*0.6,8.0*burst,backwards || inverted,backwards || inverted)
        if(t>=4.7) PartyHushGlitch_Transform(card[CARD_LINE],dx*0.3,0,true,true)
        bool gunFlip=inverted
        float gunWide=backwards ? 1.55 : inverted ? 1.18 : 0.84
        float gunTall=backwards ? 0.76 : inverted ? 1.18 : 1.08
        PartyHushGlitch_Transform(card[CARD_GUN],dx*0.55,-20.0*burst,gunFlip,gunFlip,gunWide,gunTall)
    }
    if(!extras) return
    // Opaque background strips erase each original band before its true atlas
    // subrectangle is redrawn sideways. No screenshot or extra texture atlas.
    for(int band=0;band<3;band++)
    {
        IntroImage original=card[band==0 ? CARD_GUN : band==1 ? CARD_CEAIKAS : CARD_PARTYPACK]
        IntroImage mask=card[HUSH_GLITCH_TEAR+band*2]
        IntroImage cut=card[HUSH_GLITCH_TEAR+band*2+1]
        float s=GetScreenSize()[1]/1080.0*intro.zoom
        float wide=original.w*original.drawScale*s
        float high=original.h*original.drawScale*s/3.0
        float x=GetScreenSize()[0]*0.5+original.drawX*s-wide*0.5
        float y=GetScreenSize()[1]*0.5+original.drawY*s-high*0.5
        float offset=(band==1 ? -1.0 : 1.0)*(70.0+45.0*sin(floor(t*11.0)*2.4+band))*s
        // Gun bands use its normal pose; its later flips/stretch take priority.
        float alpha=t>=3.60 && t<5.20 && (band!=0 || t<4.17) ? burst : 0.0
        PartyCard_Rect(mask,x,y,x+wide,y+high,background,alpha)
        PartyCard_Rect(cut,x+offset,y,x+wide+offset,y+high,<0.66,0.66,0.66>,alpha)
    }
    float width=GetScreenSize()[0]
    float height=GetScreenSize()[1]
    float scale=height/1080.0
    float tick=floor(t*12.0)
    for(int i=0;i<HUSH_GLITCH_BLOCKS;i++)
    {
        float size=(30.0+float((i*47+int(tick)*13)%104))*scale
        float x=(0.12+0.76*(0.5+0.5*sin(float(i)*5.7+tick*0.9)))*width
        float y=(0.18+0.58*(0.5+0.5*cos(float(i)*3.3+tick*1.1)))*height
        float w=i<8 ? size : width*0.86
        float h=i<8 ? size : (i==8 ? 4.0 : 12.0)*scale
        float tone=i%3==0 ? 0.20 : i%3==1 ? 0.006 : 0.07
        float alpha=burst*(i%3==0 ? 0.38 : 0.85)
        PartyCard_Rect(card[HUSH_GLITCH_FIRST+i],x,y,x+w,y+h,<tone,tone,tone>,alpha)
    }
    for(int i=0;i<2;i++)
    {
        IntroImage original=card[i==0 ? CARD_CEAIKAS : CARD_PARTYPACK]
        IntroImage ghost=card[HUSH_GLITCH_GHOST+i]
        float alpha=t>=3.6 && t<5.2 ? burst*0.38 : 0.0
        RuiSetFloat3(ghost.rui,"basicImageColor",<0.68,0.68,0.68>)
        PartyIntro_PlaceTurned(ghost,original.drawX+(i==0 ? -34.0 : 42.0)*burst,original.drawY+(i==0 ? 18.0 : -14.0),alpha,original.drawScale,t>=4.17 && t<4.51 ? 180.0 : 0.0)
    }
}
void function PartyHushGlitch_Sequence(array<IntroImage> card,array<var> texts,string map,string mode)
{
    bool extras=PartyHushGlitch_Extras(card)
    array<string> cues=["Menu_GameSummary_ScreenSlideIn","UI_InGame_FD_InfoCardSlideIn","UI_InGame_FD_MetaUpgradeTextAppear","Menu_GameSummary_ScreenSlideIn","Menu_LoadOut_Weapon_Select"]
    array<float> cueTimes=[0.05,0.45,1.8,2.9,INTRO_IMPACT]
    int cue=0
    bool shot=false
    print("[HushGlitch] start: original theme with synchronized glitch treatment")
    while(true)
    {
        // Match the processed audio timeline after the initial smooth-frame wait.
        float t=Time()-intro.started
        while(cue<cues.len() && t>=cueTimes[cue]) { PartyIntro_Sound(cues[cue]);cue++; }
        intro.zoom=1.0+0.03*PartyIntro_Ease((t-1.8)/4.0)
        float appear=PartyIntro_Ease((t-3.9)/0.8)
        PartyIntro_Place(card[CARD_LINE],0.0,CARD_LINE_Y+18.0*(1.0-appear),t<3.9 ? 0.0 : appear)
        bool running=true
        float drawTime=t
        if(t>=2.46 && t<INTRO_HOLD && PartyHushGlitch_Burst(t)>0.1)
            drawTime=floor(t*9.0)/9.0
        if(t<INTRO_HOLD) PartyCard_Arrival(card,texts,map,mode,drawTime,intro.spinFrom)
        else
        {
            float f=t-INTRO_HOLD
            if(!shot && f>=FIRE_AT) { shot=true;PartyIntro_Sound(FIRE_SOUND); }
            running=PartyCard_Reveal(card,f)
        }
        PartyHushGlitch_Draw(card,t,extras)
        if(!running) { print("[HushGlitch] clean handoff");return; }
        WaitFrame()
    }
}
