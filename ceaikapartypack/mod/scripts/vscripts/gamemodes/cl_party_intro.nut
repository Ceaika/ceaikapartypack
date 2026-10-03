untyped
global function PartyIntro_Init
global function PartyTransition

const vector INTRO_ORANGE = <0.9823,0.0704,0.0003>
const vector INTRO_FLASH = <1.0,0.25,0.06>
const vector INTRO_SHADOW = <0.18,0.004,0.0>
const float INTRO_HOLD = 5.2
const float INTRO_MAX_HOLD = 25.0
const float INTRO_IMPACT = 3.6
const float INTRO_READY = 4.2
const int INTRO_SORT = 5000

const string INTRO_MUSIC = "music_beacon_24a_blisktease"

const float MUZZLE_X = 7.0
const float MUZZLE_Y = -204.0

const float CORNER_GUN_X = 175.0
const float CORNER_GUN_Y = 950.0
const float CORNER_GUN_SCALE = 0.26
const float CORNER_SPIN = 100.0
const float CORNER_CEAIKAS_X = 308.1
const float CORNER_CEAIKAS_Y = 94.7
const float CORNER_CEAIKAS_SCALE = 0.82
const float CORNER_PARTYPACK_X = 423.9
const float CORNER_PARTYPACK_Y = 205.8
const float CORNER_PARTYPACK_SCALE = 0.64
const float CORNER_NAMES_RIGHT = 90.3
const float CORNER_MAP_Y = 449.2
const float CORNER_MAP_H = 59.1
const float CORNER_MODE_Y = 548.4
const float CORNER_MODE_H = 47.2

const float VGUI_MAX_TALL = 128.0
const float LOADING_MAP_FONT = 86.0
const float LOADING_MODE_FONT = 62.0
const float CARD_LINE_Y = 265.0
const float CARD_STARTING_MODE_Y = 380.0
const float CARD_STARTING_MODE_H = 62.0

const float FIRE_AT = 0.2
const float FIRE_SLIDE = 0.3
const float FIRE_OPEN = 0.95
const float FIRE_DONE = 1.6
const string FIRE_SOUND = "weapon_re45auto_firstshot_1p"
const float IRIS_OPEN = 0.6

struct IntroImage
{
    var topo
    var rui
    var shadowTopo
    var shadow
    float w
    float h
}

const int CARD_TOP = 0
const int CARD_BOTTOM = 1
const int CARD_GUN = 2
const int CARD_CEAIKAS = 3
const int CARD_PARTYPACK = 4
const int CARD_MASK = 5
const int CARD_LINE = 6
const int CARD_FLASH = 7
const int CARD_BULLET = 8
const int CARD_MAP = 9
const int CARD_MODE = 10
const int CARD_IRIS = 11
const int CARD_IRIS_LEFT = 12
const int CARD_IRIS_RIGHT = 13

struct
{
    float started = 0.0
    bool musicPlaying = false
    float zoom = 1.0
    bool quick = false
    string nextMode = ""
    string nextMap = ""
    float spinFrom = 0.0
    float clock = 0.0
    float clockAt = 0.0
} intro

void function PartyIntro_Init()
{
    AddServerToClientStringCommandCallback( "party_next", PartyIntro_NextCommand )

    if ( GetMapName() == "mp_lobby" ) return
    if ( GAMETYPE == "partylobby" )
    {
        thread PartyTransition_Arrive()
        return
    }
    if ( ["ffa","hidden","chamber","gg","inf"].contains( GAMETYPE ) ) intro.quick = true
    else if ( !["jugg","hotpotato","prophunt","bodyswap"].contains( GAMETYPE ) ) return
    thread PartyIntro_Run()
}

void function PartyIntro_NextCommand( array<string> args )
{
    if ( args.len() != 2 ) return
    intro.nextMode = args[0]
    intro.nextMap = args[1]
}

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

IntroImage function PartyIntro_Image( asset image, float w, float h, int sort, bool shadow, int shadowSort = INTRO_SORT+1 )
{
    IntroImage made
    made.topo = RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false )
    made.rui = RuiCreate( $"ui/basic_image.rpak", made.topo, RUI_DRAW_HUD, sort )
    if ( image != $"" ) RuiSetImage( made.rui, "basicImage", image )
    RuiSetFloat3( made.rui, "basicImageColor", <1,1,1> )
    RuiSetFloat( made.rui, "basicImageAlpha", 0.0 )
    if ( shadow )
    {
        made.shadowTopo = RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false )
        made.shadow = RuiCreate( $"ui/basic_image.rpak", made.shadowTopo, RUI_DRAW_HUD, shadowSort )
        RuiSetImage( made.shadow, "basicImage", image )
        RuiSetFloat3( made.shadow, "basicImageColor", INTRO_SHADOW )
        RuiSetFloat( made.shadow, "basicImageAlpha", 0.0 )
    }
    made.w = w
    made.h = h
    return made
}

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

void function PartyIntro_Place( IntroImage image, float cx, float cy, float alpha, float scale = 1.0 )
{
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

void function PartyIntro_PlaceTurned( IntroImage image, float cx, float cy, float alpha, float scale, float degrees )
{
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

float function PartyIntro_Width()
{
    return GetScreenSize()[0] / ( GetScreenSize()[1] / 1080.0 )
}

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

void function PartyCard_Create( array<IntroImage> card, array<var> texts, int sort, asset line, float lineW, float lineH, string mapKey, string modeKey, bool iris = false )
{
    card.append( PartyIntro_Image( $"", 1.0, 1.0, sort-3, false ) )
    card.append( PartyIntro_Image( $"", 1.0, 1.0, sort-3, false ) )
    card.append( PartyIntro_Image( $"rui/ceaika/intro_gun", 576.0, 494.0, sort+5, true, sort+4 ) )
    card.append( PartyIntro_Image( $"rui/ceaika/intro_ceaikas", 532.0, 148.0, sort+2, true, sort+1 ) )
    card.append( PartyIntro_Image( $"rui/ceaika/intro_partypack", 581.0, 143.0, sort+7, true, sort+6 ) )

    card.append( PartyIntro_Image( $"", 1600.0, 200.0, sort+3, false ) )
    card.append( PartyIntro_Image( line, lineW, lineH, sort+7, true, sort+6 ) )
    card.append( PartyIntro_Image( $"rui/ceaika/flash", 256.0, 256.0, sort+9, false ) )
    card.append( PartyIntro_Image( $"", 1.0, 1.0, sort+8, false ) )

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

float function PartyCorner_X( float fromLeft ) { return fromLeft - PartyIntro_Width()*0.5; }
float function PartyCorner_Y( float fromTop ) { return fromTop - 540.0; }
float function PartyCorner_Right() { return PartyIntro_Width()*0.5 - CORNER_NAMES_RIGHT; }

void function PartyCard_Gun( array<IntroImage> card, float u, float degrees, float alpha )
{
    PartyIntro_PlaceTurned( card[CARD_GUN], PartyIntro_Lerp( -281.0, PartyCorner_X( CORNER_GUN_X ), u ), PartyIntro_Lerp( -70.0, PartyCorner_Y( CORNER_GUN_Y ), u ), alpha, PartyIntro_Lerp( 1.0, CORNER_GUN_SCALE, u ), degrees )
}

float function PartyCard_Spin()
{
    return ( Time()*CORNER_SPIN ) % 360.0
}

void function PartyCard_Title( array<IntroImage> card, float u, float alpha )
{
    PartyIntro_Place( card[CARD_CEAIKAS], PartyIntro_Lerp( 303.0, PartyCorner_X( CORNER_CEAIKAS_X ), u ), PartyIntro_Lerp( -204.0, PartyCorner_Y( CORNER_CEAIKAS_Y ), u ), alpha, PartyIntro_Lerp( 1.0, CORNER_CEAIKAS_SCALE, u ) )
    PartyIntro_Place( card[CARD_PARTYPACK], PartyIntro_Lerp( 48.0, PartyCorner_X( CORNER_PARTYPACK_X ), u ), PartyIntro_Lerp( -35.0, PartyCorner_Y( CORNER_PARTYPACK_Y ), u ), alpha, PartyIntro_Lerp( 1.0, CORNER_PARTYPACK_SCALE, u ) )
}

void function PartyCard_Corner( array<IntroImage> card, array<var> texts, string map, string mode, float alpha )
{
    PartyCard_Back( card, 0.0, 0.0, 0.0, INTRO_ORANGE, 1.0 )
    PartyCard_Gun( card, 1.0, PartyCard_Spin(), 1.0 )
    PartyCard_CornerOut( card, texts, map, mode, 0.0 )
    PartyIntro_Place( card[CARD_MASK], 0.0, 0.0, 0.0 )
    RuiSetFloat3( card[CARD_MASK].rui, "basicImageColor", INTRO_ORANGE )
}

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

void function PartyIntro_DrawLogo( array<IntroImage> card, float t, float dy, float out, bool gunInPlace = false )
{
    float width = PartyIntro_Width()

    float decay = t < INTRO_IMPACT ? 0.0 : max( 0.0, 1.0 - (t-INTRO_IMPACT)/0.35 )
    float shakeX = 7.0*decay*sin( t*71.0 )
    float shakeY = 5.0*decay*cos( t*53.0 ) + dy

    float gunStart = -width*0.5 - 330.0
    float gunX = gunInPlace ? -281.0 : gunStart + (-281.0-gunStart)*PartyIntro_EaseBack( (t-0.9)/1.1 )
    float gunDrawX = gunX + shakeX - 8.0*decay
    PartyIntro_Place( card[CARD_GUN], gunDrawX, -70.0 + shakeY, gunInPlace || t >= 0.9 ? out : 0.0 )

    float muzzle = gunDrawX + 288.0 - 6.0
    PartyIntro_Place( card[CARD_MASK], muzzle - 800.0, -204.0 + shakeY, t < 0.9 ? 0.0 : out )
    float slide = PartyIntro_Ease( (t-1.8)/1.3 )
    float hiddenX = -281.0 + 288.0 - 6.0 - 266.0 - 12.0
    PartyIntro_Place( card[CARD_CEAIKAS], hiddenX + (303.0-hiddenX)*slide + shakeX, -204.0 + shakeY, t < 1.8 ? 0.0 : out )

    float partyX = 48.0
    float partyStart = width*0.5 + 330.0
    float x = partyStart
    if ( t >= 2.9 && t < INTRO_IMPACT ) { float u = (t-2.9)/(INTRO_IMPACT-2.9); x = partyStart + (partyX-partyStart)*u*u; }
    else if ( t >= INTRO_IMPACT ) { float u = clamp( (t-INTRO_IMPACT)/0.55, 0.0, 1.0 ); x = partyX + 38.0*sin( u*PI )*(1.0-u); }
    PartyIntro_Place( card[CARD_PARTYPACK], x + shakeX, -35.0 + shakeY, t < 2.9 ? 0.0 : out )
}

void function PartyCard_Arrival( array<IntroImage> card, array<var> texts, string map, string mode, float t, float spinFrom )
{

    float back = PartyIntro_EaseInOut( (t-0.45)/1.3 )
    float flash = t < INTRO_IMPACT ? 0.0 : max( 0.0, 1.0 - (t-INTRO_IMPACT)/0.25 )
    vector color = INTRO_ORANGE + (INTRO_FLASH-INTRO_ORANGE)*flash
    PartyCard_Back( card, 0.0, 0.0, 0.0, color, 1.0 )
    RuiSetFloat3( card[CARD_MASK].rui, "basicImageColor", color )
    if ( t < 1.8 )
    {

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

bool function PartyCard_Reveal( array<IntroImage> card, float f )
{
    float width = PartyIntro_Width()
    float s = GetScreenSize()[1] / 1080.0
    PartyIntro_Place( card[CARD_MASK], 0.0, 0.0, 0.0 )

    float gone = 1.0 - clamp( f/FIRE_AT, 0.0, 1.0 )
    PartyIntro_Place( card[CARD_CEAIKAS], 303.0, -204.0, gone, 0.9 + 0.1*gone )
    PartyIntro_Place( card[CARD_PARTYPACK], 48.0, -35.0, gone, 0.9 + 0.1*gone )

    float shot = f - FIRE_AT
    float kick = shot < 0.0 ? 0.0 : sin( clamp( shot/0.2, 0.0, 1.0 )*PI )*( 1.0 - clamp( shot/0.2, 0.0, 1.0 ) )
    float slide = ( width*0.5 + 650.0 )*PartyIntro_EaseIn( (f-FIRE_SLIDE)/(FIRE_OPEN-FIRE_SLIDE) )
    float gunX = -281.0 - 18.0*kick - slide
    PartyIntro_Place( card[CARD_GUN], gunX, -70.0, 1.0 )
    float muzzle = gunX + 288.0

    float pop = shot < 0.0 ? 0.0 : clamp( shot/0.06, 0.0, 1.0 )
    float flash = shot < 0.0 ? 0.0 : 1.0 - clamp( (shot-0.04)/0.18, 0.0, 1.0 )
    PartyIntro_Place( card[CARD_FLASH], muzzle + 26.0, MUZZLE_Y, pop*flash, 0.4 + 0.6*pop )

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

    PartyCard_Rect( card[CARD_TOP], -40.0, -40.0, width + 40.0, y0 + 1.0, INTRO_ORANGE, 1.0 )
    PartyCard_Rect( card[CARD_BOTTOM], -40.0, y1 - 1.0, width + 40.0, height + 40.0, INTRO_ORANGE, 1.0 )
    PartyCard_Rect( card[CARD_IRIS_LEFT], -40.0, y0, x0 + 1.0, y1, INTRO_ORANGE, 1.0 )
    PartyCard_Rect( card[CARD_IRIS_RIGHT], x1 - 1.0, y0, width + 40.0, y1, INTRO_ORANGE, 1.0 )
    PartyCard_Rect( card[CARD_IRIS], x0, y0, x1, y1, INTRO_ORANGE, d > 1.0 ? 1.0 : 0.0 )
}

bool function PartyCard_IrisReveal( array<IntroImage> card, float f )
{
    PartyIntro_Place( card[CARD_MASK], 0.0, 0.0, 0.0 )
    float cock = PartyIntro_EaseInOut( f/FIRE_AT )
    float shot = f - FIRE_AT

    float reach = 2.0*sqrt( pow( PartyIntro_Width()*0.5 + fabs( MUZZLE_X ), 2 ) + pow( 540.0 + fabs( MUZZLE_Y ), 2 ) ) + 80.0
    PartyCard_Hole( card, shot < 0.0 ? 0.0 : reach*pow( clamp( shot/IRIS_OPEN, 0.0, 1.0 ), 1.7 ) )
    float shake = shot < 0.0 ? 0.0 : max( 0.0, 1.0 - shot/0.25 )
    float sx = 9.0*shake*sin( f*83.0 )
    float sy = 7.0*shake*cos( f*61.0 )
    float blow = shot < 0.0 ? 0.0 : PartyIntro_Ease( shot/0.45 )
    float gone = shot < 0.0 ? 1.0 : 1.0 - clamp( (shot-0.1)/0.3, 0.0, 1.0 )

    float gunX = -281.0 - 22.0*cock - 260.0*blow + sx
    PartyIntro_Place( card[CARD_GUN], gunX, -70.0 + 40.0*blow + sy, gone )

    PartyIntro_Place( card[CARD_CEAIKAS], 303.0 + 320.0*blow + sx, -204.0 - 120.0*blow + sy, gone, 1.0 + 0.35*blow )
    PartyIntro_Place( card[CARD_PARTYPACK], 48.0 + 380.0*blow + sx, -35.0 + 140.0*blow + sy, gone, 1.0 + 0.35*blow )

    float pop = shot < 0.0 ? 0.0 : clamp( shot/0.08, 0.0, 1.0 )
    float fade = shot < 0.0 ? 0.0 : 1.0 - clamp( (shot-0.05)/0.22, 0.0, 1.0 )
    PartyIntro_Place( card[CARD_FLASH], gunX + 288.0 + 26.0, MUZZLE_Y + sy, pop*fade, 0.6 + 1.2*pop )
    return shot < IRIS_OPEN + 0.05
}

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

void function PartyIntro_Run()
{

    if ( GetGameState() >= eGameState.Playing ) return
    printt( "[PartyIntro] playing" )
    string mapKey = GetMapName()
    string modeKey = GetCurrentPlaylistName()
    array<IntroImage> card
    array<var> texts
    PartyCard_Create( card, texts, INTRO_SORT, $"rui/ceaika/intro_presents", 573.0, 140.0, mapKey, modeKey )
    OnThreadEnd( function() : ( card, texts )
    {
        PartyCard_Destroy( card, texts )
    } )
    string map = PartyCard_MapName( mapKey )
    string mode = PartyCard_ModeName( modeKey )

    while ( !IsValid( GetLocalClientPlayer() ) )
    {
        PartyCard_Corner( card, texts, map, mode, 1.0 )
        WaitFrame()
    }
    PartyIntro_WaitSmooth( card, texts, map, mode )
    if ( GetGameState() >= eGameState.Playing ) return
    intro.started = Time()
    intro.spinFrom = PartyCard_Spin()

    entity player = GetLocalClientPlayer()
    if ( IsValid( player ) ) { EmitSoundOnEntity( player, INTRO_MUSIC ); intro.musicPlaying = true; }
    waitthread PartyIntro_Sequence( card, texts, map, mode )

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

        if ( fireAt < 0.0 && ( t >= INTRO_HOLD || ( intro.quick && t >= 1.8 ) ) && ( GetGameState() >= eGameState.Playing || t >= INTRO_MAX_HOLD ) )
        {
            fireAt = t
        }

        if ( fireAt < 0.0 ) intro.zoom = 1.0 + 0.03*PartyIntro_Ease( (t-1.8)/4.0 )

        float appear = PartyIntro_Ease( (t-3.9)/0.8 )
        PartyIntro_Place( card[CARD_LINE], 0.0, CARD_LINE_Y + 18.0*(1.0-appear), t < 3.9 ? 0.0 : appear )
        if ( fireAt >= 0.0 )
        {

            PartyCard_Name( card, texts, CARD_MAP, map, 0.0, 0.0, CORNER_MAP_H, 0.0 )
            PartyCard_Name( card, texts, CARD_MODE, mode, 0.0, 0.0, CORNER_MODE_H, 0.0 )
            if ( !shot && t - fireAt >= FIRE_AT ) { shot = true; PartyIntro_Sound( FIRE_SOUND ); }
            if ( !PartyCard_Reveal( card, t - fireAt ) ) return
        }
        else PartyCard_Arrival( card, texts, map, mode, t, intro.spinFrom )
        WaitFrame()
    }
}

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

void function PartyIntro_StopMusic( float fade )
{
    if ( !intro.musicPlaying ) return
    intro.musicPlaying = false
    entity player = GetLocalClientPlayer()
    if ( !IsValid( player ) ) return
    if ( fade > 0.0 ) FadeOutSoundOnEntity( player, INTRO_MUSIC, fade )
    else StopSoundOnEntity( player, INTRO_MUSIC )
}

const float TRANSITION_SPEED = 1.6
const float TRANSITION_LOGO = 0.6
const float TRANSITION_CORNER = 3.0
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

void function PartyTransition_Scoreboard()
{
    transition.scoreboard = true
    ShowScoreboard()
    printt( "[PartyIntro] scoreboard" )
}

string function PartyTransition_ModeKey( int mode )
{
    array<string> keys = ["jugg","hotpotato","prophunt","bodyswap","ffa","hidden","chamber","gg","inf"]
    return mode >= 0 && mode < keys.len() ? keys[mode] : ""
}

float function PartyTransition_LogoTime( float t )
{
    return 0.9 + ( t - TRANSITION_LOGO ) * TRANSITION_SPEED
}

float function PartyTransition_Blink( float since )
{
    if ( since < 0.0 ) return 0.0
    float appear = PartyIntro_Ease( since/0.35 )
    float blink = since - 0.6
    if ( blink >= 0.0 && blink < 0.9 && int( blink / 0.15 ) % 2 == 0 ) return 0.12
    return appear
}

void function PartyTransition_Arrive()
{
    transition.active = true
    intro.zoom = 1.0
    string mapKey = GetMapName()
    string modeKey = GetCurrentPlaylistName()
    array<IntroImage> card
    array<var> texts
    PartyCard_Create( card, texts, INTRO_SORT+20, $"rui/ceaika/intro_presents", 573.0, 140.0, mapKey, modeKey, true )
    OnThreadEnd( function() : ( card, texts )
    {
        PartyCard_Destroy( card, texts )
        transition.active = false
    } )
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

    PartyVoteBoards_Release()
    PartyCredits_Release()
    PartyStatue_Release()
    transition.active = true
    intro.zoom = 1.0
    bool starting = kind == 1

    string modeKey = intro.nextMode != "" ? intro.nextMode : ( starting ? PartyTransition_ModeKey( mode ) : "partylobby" )
    string mapKey = intro.nextMap != "" ? intro.nextMap : ( starting ? "" : "mp_coliseum" )
    array<IntroImage> card
    array<var> texts
    PartyCard_Create( card, texts, INTRO_SORT+20, starting ? $"rui/ceaika/intro_starting" : $"rui/ceaika/intro_redirecting", starting ? 914.0 : 879.0, 110.0, mapKey, modeKey )
    OnThreadEnd( function() : ( card, texts )
    {
        PartyCard_Destroy( card, texts )
        transition.active = false
    } )
    string map = PartyCard_MapName( mapKey )
    string toMode = PartyCard_ModeName( modeKey )
    printt( "[PartyIntro] transition " + kind + " to " + toMode + " / " + map )
    PartyIntro_Sound( kind == 0 ? "Menu_GameSummary_ScreenSlideIn" : "UI_InGame_HalftimeText_Enter" )

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

        float drop = 0.0
        float sweep = 0.0
        if ( kind == 0 ) drop = -1100.0*( 1.0 - PartyIntro_EaseBack( t/0.65 ) )
        else sweep = width*( 1.0 - PartyIntro_EaseBack( t/0.55 ) )

        if ( transition.scoreboard && kind == 0 ) { transition.scoreboard = false; HideScoreboard(); }
        float flash = logo < INTRO_IMPACT ? 0.0 : max( 0.0, 1.0 - (logo-INTRO_IMPACT)/0.25 )
        vector color = INTRO_ORANGE + (INTRO_FLASH-INTRO_ORANGE)*flash
        PartyCard_Back( card, sweep, drop, 0.0, color, 1.0 )
        RuiSetFloat3( card[CARD_MASK].rui, "basicImageColor", color )

        float m = t - TRANSITION_CORNER
        if ( m >= 0.0 && !cornerSound ) { cornerSound = true; PartyIntro_Sound( "Menu_GameSummary_ScreenSlideIn" ); }
        float titleU = PartyIntro_EaseInOut( m/0.65 )
        float gunU = PartyIntro_EaseInOut( (m-0.12)/0.68 )
        if ( m < 0.0 ) PartyIntro_DrawLogo( card, logo, drop, 1.0 )
        else
        {
            PartyIntro_Place( card[CARD_MASK], 0.0, 0.0, 0.0 )
            PartyCard_Title( card, titleU, 1.0 )

            if ( spinBase < 0.0 ) spinBase = PartyCard_Spin()
            PartyCard_Gun( card, gunU, ( spinBase + CORNER_SPIN*m )*gunU, 1.0 )
        }

        float away = clamp( m/0.25, 0.0, 1.0 )
        float words = PartyTransition_Blink( t - phraseAt ) * ( 1.0 - away )
        float rise = 18.0*( 1.0 - PartyIntro_Ease( (t-phraseAt)/0.35 ) ) + 24.0*away
        PartyIntro_Place( card[CARD_LINE], 0.0, CARD_LINE_Y + rise + drop, words )

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
