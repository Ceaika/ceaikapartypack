global function PartyStatue_ClientInit

const float ST_TITLE_Z = 322.0
const float ST_NAME_Z = 292.0
const float ST_WINS_Z = 252.0
const float ST_TITLE_H = 22.0
const float ST_TITLE_ASPECT = 6.267
const float ST_WINS_ASPECT = 2.279
const float ST_DIGIT_H = 46.0
const float ST_DIGIT_ASPECT = 0.7297
const float ST_NAME_SIZE = 150.0
const float ST_PLANE_W = 330.0
const float ST_PLANE_H = 185.625

const vector ST_GOLD = <1.0,0.78,0.2>
const vector ST_NAME = <1.0,0.86,0.4>
const vector ST_OUTLINE = <0.05,0.03,0.0>

const int SQ_TITLE = 0
const int SQ_TENS = 1
const int SQ_ONES = 2
const int SQ_WINS = 3
const int SQ_NAME = 4

struct
{
    array<var> topos
    array<var> ruis
    var name
    array<var> outline
    int wins = 0
    string leader = ""
    float changedAt = -99.0
} statue

void function PartyStatue_ClientInit()
{
    AddServerToClientStringCommandCallback( "party_leader", PartyStatue_Command )
    thread PartyStatue_Run()
}

void function PartyStatue_Command( array<string> args )
{
    int wins = args.len() > 0 ? args[0].tointeger() : 0
    string name = args.len() > 1 ? args[1] : ""
    if ( wins == statue.wins && name == statue.leader ) return
    statue.wins = wins
    statue.leader = name
    statue.changedAt = Time()
}

bool function ST_Create()
{
    array<asset> images = [ $"rui/ceaika/holo_session_titan", $"", $"", $"rui/ceaika/holo_wins", $"" ]
    foreach ( asset image in images )
    {
        var topo

        try { topo = RuiTopology_CreatePlane( <0,0,0>, <0,1,0>, <0,0,-1>, true ) }
        catch ( ex ) { ST_Destroy(); return false }
        var rui = RuiCreate( $"ui/basic_image.rpak", topo, RUI_DRAW_WORLD, 0 )
        if ( image != $"" ) RuiSetImage( rui, "basicImage", image )
        RuiSetFloat3( rui, "basicImageColor", ST_GOLD )
        RuiSetFloat( rui, "basicImageAlpha", 0.0 )
        statue.topos.append( topo )
        statue.ruis.append( rui )
    }
    for ( int i = 0; i < 4; i++ ) statue.outline.append( ST_NameText( ST_OUTLINE, 0.6, 1 ) )
    statue.name = ST_NameText( ST_NAME, 0.3, 2 )
    return true
}

var function ST_NameText( vector color, float thicken, int sort )
{
    var rui = RuiCreate( $"ui/cockpit_console_text_top_left.rpak", statue.topos[SQ_NAME], RUI_DRAW_WORLD, sort )
    RuiSetInt( rui, "maxLines", 1 )
    RuiSetInt( rui, "lineNum", 0 )
    RuiSetFloat( rui, "thicken", thicken )
    RuiSetFloat( rui, "msgFontSize", ST_NAME_SIZE )
    RuiSetFloat3( rui, "msgColor", color )
    RuiSetFloat( rui, "msgAlpha", 0.0 )
    return rui
}

void function ST_Destroy()
{
    if ( statue.name != null ) RuiDestroyIfAlive( statue.name )
    statue.name = null
    foreach ( var rui in statue.outline ) RuiDestroyIfAlive( rui )
    statue.outline.clear()
    foreach ( var rui in statue.ruis ) RuiDestroyIfAlive( rui )
    foreach ( var topo in statue.topos ) RuiTopology_Destroy( topo )
    statue.ruis.clear()
    statue.topos.clear()
}

void function PartyStatue_Run()
{
    OnThreadEnd( function() { ST_Destroy(); } )
    float retryAt = 0.0
    while ( true )
    {
        WaitFrame()
        entity player = GetLocalViewPlayer()
        array<entity> found = GetEntArrayByScriptName( "party_statue" )
        bool show = IsValid( player ) && found.len() > 0 && statue.wins > 0 && statue.leader != ""
        if ( !show )
        {
            foreach ( var rui in statue.ruis ) RuiSetFloat( rui, "basicImageAlpha", 0.0 )
            if ( statue.name != null ) RuiSetFloat( statue.name, "msgAlpha", 0.0 )
            foreach ( var rui in statue.outline ) RuiSetFloat( rui, "msgAlpha", 0.0 )
            continue
        }
        if ( statue.ruis.len() == 0 )
        {
            if ( Time() < retryAt ) continue
            if ( !ST_Create() ) { retryAt = Time() + 1.0; continue; }
        }
        ST_Draw( player, found[0].GetOrigin() )
    }
}

float function ST_Ease( float u ) { u = clamp( u, 0.0, 1.0 ); return 1.0 - (1.0-u)*(1.0-u)*(1.0-u); }

void function ST_Quad( int index, vector base, vector toward, float x, float z, float w, float h, float alpha )
{
    vector right = CrossProduct( toward, <0,0,1> )
    vector origin = base + <0,0,z> + right*( x - w*0.5 ) + <0,0,h*0.5>
    RuiTopology_UpdatePos( statue.topos[index], origin, right*max( w, 0.01 ), < 0, 0, -max( h, 0.01 ) > )
    RuiSetFloat( statue.ruis[index], "basicImageAlpha", w > 0.05 && h > 0.05 ? clamp( alpha, 0.0, 1.0 ) : 0.0 )
}

void function ST_Draw( entity player, vector base )
{
    vector eye = player.EyePosition()
    vector flat = < eye.x - base.x, eye.y - base.y, 0 >
    vector toward = Length( flat ) > 1.0 ? Normalize( flat ) : <1,0,0>

    float t = Time() - statue.changedAt
    float settle = ST_Ease( t/0.5 )
    float jitter = t < 0.5 ? 5.0*sin( t*91.0 )*( 1.0 - settle ) : 0.0
    float flicker = t < 0.5 ? ( sin( t*57.0 ) > 0.1 ? 1.0 : 0.4 + 0.6*settle ) : 0.93 + 0.05*sin( Time()*19.0 ) + 0.02*sin( Time()*53.0 )
    float bob = 4.0*sin( Time()*1.3 )
    float grow = 0.85 + 0.15*settle

    ST_Quad( SQ_TITLE, base, toward, jitter, ST_TITLE_Z + bob, ST_TITLE_H*ST_TITLE_ASPECT*grow, ST_TITLE_H*grow, flicker )

    int wins = minint( 99, statue.wins )
    float dh = ST_DIGIT_H*grow
    float dw = dh*ST_DIGIT_ASPECT
    float lh = 18.0*grow
    float lw = lh*ST_WINS_ASPECT
    int digits = wins >= 10 ? 2 : 1
    float total = dw*( digits == 2 ? 1.82 : 1.0 ) + 6.0 + lw
    float left = -total*0.5 + jitter
    float z = ST_WINS_Z + bob
    RuiSetImage( statue.ruis[SQ_TENS], "basicImage", PartyHolo_Digit( ( wins/10 ) % 10 ) )
    RuiSetImage( statue.ruis[SQ_ONES], "basicImage", PartyHolo_Digit( wins % 10 ) )
    ST_Quad( SQ_TENS, base, toward, left + dw*0.5, z, dw, dh, digits == 2 ? flicker : 0.0 )
    float onesX = left + dw*( digits == 2 ? 1.32 : 0.5 )
    ST_Quad( SQ_ONES, base, toward, onesX, z, dw, dh, flicker )
    ST_Quad( SQ_WINS, base, toward, onesX + dw*0.5 + 6.0 + lw*0.5, z - dh*0.5 + lh*0.62, lw, lh, flicker )

    string name = statue.leader.toupper()
    float width = name.len()*ST_NAME_SIZE*0.6/1920.0
    ST_Quad( SQ_NAME, base, toward, jitter, ST_NAME_Z + bob, ST_PLANE_W, ST_PLANE_H, 0.0 )
    float x = 0.5 - width*0.5
    float y = 0.5 - ST_NAME_SIZE/1080.0*0.5
    RuiSetString( statue.name, "msgText", name )
    RuiSetFloat2( statue.name, "msgPos", < x, y, 0 > )
    RuiSetFloat( statue.name, "msgAlpha", flicker*settle )

    array<float> dx = [ -0.004, 0.004, -0.004, 0.004 ]
    array<float> dy = [ -0.007, -0.007, 0.007, 0.007 ]
    for ( int i = 0; i < statue.outline.len(); i++ )
    {
        RuiSetString( statue.outline[i], "msgText", name )
        RuiSetFloat2( statue.outline[i], "msgPos", < x + dx[i], y + dy[i], 0 > )
        RuiSetFloat( statue.outline[i], "msgAlpha", 0.9*flicker*settle )
    }
}
