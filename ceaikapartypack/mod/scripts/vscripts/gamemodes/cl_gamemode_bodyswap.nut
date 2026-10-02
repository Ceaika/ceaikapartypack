global function Cl_BodySwap_Init

const vector BS_ORANGE = <0.9823,0.0704,0.0003>
const vector BS_SHADOW = <0.18,0.004,0.0>
const float BS_DIGIT_HEIGHT = 150.0
const float BS_DIGIT_Y = -285.0
const float BS_DIGIT_ALPHA = 0.8

struct
{
    var topo
    var rui
    var shadowTopo
    var shadow
    int shownDigit = 0
} bsHud

void function Cl_BodySwap_Init()
{
    thread BS_HudThink()
}

var function BS_HudImage( var topo, vector color, int sort )
{
    var rui = RuiCreate( $"ui/basic_image.rpak", topo, RUI_DRAW_HUD, sort )
    RuiSetFloat3( rui, "basicImageColor", color )
    RuiSetFloat( rui, "basicImageAlpha", 0.0 )
    return rui
}

asset function BS_DigitImage( int digit )
{
    if ( digit == 3 ) return $"rui/ceaika/swap_3"
    if ( digit == 2 ) return $"rui/ceaika/swap_2"
    return $"rui/ceaika/swap_1"
}

float function BS_DigitAspect( int digit )
{
    if ( digit == 3 ) return 189.0 / 300.0
    if ( digit == 2 ) return 196.0 / 297.0
    return 125.0 / 294.0
}

void function BS_HudThink()
{
    while ( !IsValid( GetLocalClientPlayer() ) ) WaitFrame()
    bsHud.shadowTopo = RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false )
    bsHud.shadow = BS_HudImage( bsHud.shadowTopo, BS_SHADOW, 120 )
    bsHud.topo = RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false )
    bsHud.rui = BS_HudImage( bsHud.topo, BS_ORANGE, 121 )
    while ( true )
    {
        BS_HudDraw()
        WaitFrame()
    }
}

float function BS_EaseOutBack( float u )
{
    u = clamp( u, 0.0, 1.0 )
    float v = u - 1.0
    return 1.0 + 2.2*v*v*v + 1.2*v*v
}

void function BS_HudDraw()
{
    entity player = GetLocalViewPlayer()
    float swapAt = GetGlobalNetTime( "bsNextSwap" )
    float left = swapAt - Time()
    bool shown = swapAt > 0.0 && left > 0.0 && left <= 3.0 && IsValid( player ) && IsAlive( player ) && GetGameState() == eGameState.Playing
    if ( !shown )
    {
        RuiSetFloat( bsHud.rui, "basicImageAlpha", 0.0 )
        RuiSetFloat( bsHud.shadow, "basicImageAlpha", 0.0 )
        bsHud.shownDigit = 0
        return
    }
    int digit = int( ceil( left ) )
    if ( digit != bsHud.shownDigit )
    {
        bsHud.shownDigit = digit
        RuiSetImage( bsHud.rui, "basicImage", BS_DigitImage( digit ) )
        RuiSetImage( bsHud.shadow, "basicImage", BS_DigitImage( digit ) )
        EmitSoundOnEntity( GetLocalClientPlayer(), "UI_InGame_HalftimeText_Enter" )
    }

    float u = 1.0 - ( left - float( digit - 1 ) )
    float scale = 1.0
    float alpha = 1.0
    if ( u < 0.22 )
    {

        float t = u / 0.22
        scale = 1.0 + 0.6 * ( 1.0 - BS_EaseOutBack( t ) )
        alpha = clamp( t * 3.0, 0.0, 1.0 )
    }
    else if ( u > 0.8 )
    {

        float t = ( u - 0.8 ) / 0.2
        scale = 1.0 + 0.25 * t
        alpha = 1.0 - t
    }

    float shake = u < 0.3 ? ( 0.3 - u ) / 0.3 : 0.0

    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    float h = BS_DIGIT_HEIGHT * s * scale
    float w = h * BS_DigitAspect( digit )
    float x = width*0.5 - w*0.5 + 5.0*s*shake*sin( Time()*90.0 )
    float y = height*0.5 + BS_DIGIT_Y*s - h*0.5 + 4.0*s*shake*cos( Time()*70.0 )
    RuiTopology_UpdatePos( bsHud.shadowTopo, <x + 5.0*s*scale, y + 6.0*s*scale, 0>, <w,0,0>, <0,h,0> )
    RuiTopology_UpdatePos( bsHud.topo, <x, y, 0>, <w,0,0>, <0,h,0> )
    RuiSetFloat( bsHud.rui, "basicImageAlpha", alpha * BS_DIGIT_ALPHA )
    RuiSetFloat( bsHud.shadow, "basicImageAlpha", alpha * BS_DIGIT_ALPHA * 0.55 )
}
