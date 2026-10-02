global function PartyVoteBoards_Init
global function PartyHolo_Digit

const int VB_MODES = 9
const float VB_OPEN = 210.0
const float VB_CLOSE = 270.0
const float VB_NAME_Z = 96.0
const float VB_BEAM_Z = 44.0
const float VB_BOTTOM = 70.0
const float VB_W = 136.0
const float VB_H = 56.0
const float VB_PAD = 8.0
const float VB_NAME_H = 13.0
const float VB_DIGIT_H = 24.0
const float VB_DIGIT_ASPECT = 0.7297
const float VB_TEXT_H = 76.5

const vector VB_ORANGE = <0.992,0.294,0.004>
const vector VB_GREEN = <0.3,0.92,0.46>
const vector VB_GLASS = <0.01,0.012,0.02>
const vector VB_SOFT = <0.93,0.95,0.97>
const vector VB_DIM = <0.78,0.81,0.86>

const int VQ_BEAM = 0
const int VQ_PANEL = 1
const int VQ_BRACKETS = 2
const int VQ_SWEEP = 3
const int VQ_LINE = 4
const int VQ_TEXT = 5
const int VQ_TENS = 6
const int VQ_ONES = 7
const int VQ_NAME = 8

struct
{
    array<var> topos
    array<var> ruis
    array<var> texts
    array<entity> panels
    array<float> aspect
    int at = -1
    bool open = false
    float openT = 0.0
    int lastVotes = -1
    float popAt = -99.0
    int lastVote = -2
    float flashAt = -99.0
} board

void function PartyVoteBoards_Init()
{
    thread VB_Run()
}

string function VB_Key( int i ) { return ["jugg","hotpotato","prophunt","bodyswap","ffa","hidden","chamber","gg","inf"][i]; }

string function VB_Description( int i )
{
    switch ( i )
    {
        case 0: return "One giant Titan.\nEveryone else hunts it."
        case 1: return "Melee to pass the potato\nbefore it blows."
        case 2: return "Props hide as objects.\nHunters have 3:30 to find them."
        case 3: return "Swap bodies with a random enemy\nevery few seconds."
        case 4: return "Every pilot for themselves.\nMost kills wins."
        case 5: return "One invisible Hidden\nagainst everyone else."
        case 6: return "One bullet, one kill.\nMiss and it's your fists."
        case 7: return "Every kill gives you\nthe next weapon."
        case 8: return "Die and you join the infected.\nThree rounds."
    }
    return ""
}

float function VB_Ease( float u ) { u = clamp( u, 0.0, 1.0 ); return 1.0 - (1.0-u)*(1.0-u)*(1.0-u); }
float function VB_EaseInOut( float u ) { u = clamp( u, 0.0, 1.0 ); return u*u*(3.0-2.0*u); }
vector function VB_Mix( vector a, vector b, float u ) { return a + ( b - a )*clamp( u, 0.0, 1.0 ); }

var function VB_Text( var topo, float size, vector color, float x, float y )
{
    var rui = RuiCreate( $"ui/cockpit_console_text_top_left.rpak", topo, RUI_DRAW_WORLD, 2 )
    RuiSetInt( rui, "maxLines", 3 )
    RuiSetInt( rui, "lineNum", 0 )
    RuiSetFloat( rui, "thicken", 0.0 )
    RuiSetFloat( rui, "msgFontSize", size )
    RuiSetFloat3( rui, "msgColor", color )
    RuiSetFloat( rui, "msgAlpha", 0.0 )
    RuiSetFloat2( rui, "msgPos", <x,y,0> )
    return rui
}

bool function VB_Create()
{
    array<asset> images = [ $"rui/ceaika/holo_beam", $"rui/ceaika/holo_panel", $"rui/ceaika/holo_brackets", $"rui/ceaika/holo_sweep", $"", $"", $"", $"" ]
    for ( int i = 0; i < VB_MODES; i++ ) images.append( PartyName_Image( VB_Key( i ) ) )
    foreach ( asset image in images )
    {
        var topo

        try { topo = RuiTopology_CreatePlane( <0,0,0>, <0,1,0>, <0,0,-1>, true ) }
        catch ( ex ) { VB_Destroy(); return false }
        var rui = RuiCreate( $"ui/basic_image.rpak", topo, RUI_DRAW_WORLD, 0 )
        if ( image != $"" ) RuiSetImage( rui, "basicImage", image )
        RuiSetFloat( rui, "basicImageAlpha", 0.0 )
        board.topos.append( topo )
        board.ruis.append( rui )
    }
    RuiSetFloat3( board.ruis[VQ_LINE], "basicImageColor", <1,1,1> )
    board.texts.append( VB_Text( board.topos[VQ_TEXT], 76.0, VB_SOFT, 0.06, 0.335 ) )
    board.texts.append( VB_Text( board.topos[VQ_TEXT], 64.0, VB_DIM, 0.06, 0.56 ) )
    board.texts.append( VB_Text( board.topos[VQ_TEXT], 54.0, VB_DIM, 0.868, 0.45 ) )
    board.aspect.clear()
    for ( int i = 0; i < VB_MODES; i++ ) board.aspect.append( PartyName_Aspect( VB_Key( i ) ) )
    return true
}

void function VB_Destroy()
{
    foreach ( var rui in board.texts ) RuiDestroyIfAlive( rui )
    foreach ( var rui in board.ruis ) RuiDestroyIfAlive( rui )
    foreach ( var topo in board.topos ) RuiTopology_Destroy( topo )
    board.texts.clear()
    board.ruis.clear()
    board.topos.clear()
}

void function VB_Run()
{
    OnThreadEnd( function() { VB_Destroy(); } )
    for ( int i = 0; i < VB_MODES; i++ ) board.panels.append( null )
    float last = Time()
    float retryAt = 0.0
    while ( true )
    {
        WaitFrame()
        float dt = Time() - last
        last = Time()
        entity player = GetLocalViewPlayer()
        if ( !IsValid( player ) ) continue
        bool any = false
        for ( int i = 0; i < VB_MODES; i++ )
        {
            if ( !IsValid( board.panels[i] ) )
            {
                array<entity> found = GetEntArrayByScriptName( "party_vote_" + i )
                board.panels[i] = found.len() > 0 ? found[0] : null
            }
            if ( IsValid( board.panels[i] ) ) any = true
        }
        if ( !any ) continue
        if ( board.ruis.len() == 0 )
        {
            if ( Time() < retryAt ) continue
            if ( !VB_Create() ) { retryAt = Time() + 1.0; continue; }
        }

        vector eye = player.EyePosition()
        int nearest = -1
        float best = 99999.0
        for ( int i = 0; i < VB_MODES; i++ )
        {
            if ( !IsValid( board.panels[i] ) ) continue
            float d = VB_Flat( eye, board.panels[i].GetOrigin() )
            if ( d < best ) { best = d; nearest = i; }
        }
        bool wasOpen = board.open
        if ( board.open && board.at >= 0 && IsValid( board.panels[board.at] ) && VB_Flat( eye, board.panels[board.at].GetOrigin() ) > VB_CLOSE ) board.open = false
        if ( !board.open && board.openT <= 0.0 && nearest >= 0 && best < VB_OPEN ) { board.open = true; board.at = nearest; board.lastVotes = -1; }
        if ( board.open && !wasOpen ) EmitSoundOnEntity( player, "UI_InGame_FD_InfoCardSlideIn" )
        board.openT = board.open ? min( board.openT + dt, 3.0 ) : max( 0.0, min( board.openT, 0.8 ) - dt*2.5 )
        VB_Draw( player )
    }
}

float function VB_Flat( vector a, vector b ) { return Length( < a.x - b.x, a.y - b.y, 0 > ); }

vector function VB_Toward( entity panel, vector eye )
{
    vector flat = < eye.x - panel.GetOrigin().x, eye.y - panel.GetOrigin().y, 0 >
    return Length( flat ) > 1.0 ? Normalize( flat ) : <1,0,0>
}

void function VB_Quad( int index, entity panel, vector toward, float x, float z, float w, float h, float depth, float alpha )
{
    vector right = CrossProduct( toward, <0,0,1> )
    vector centre = panel.GetOrigin() + <0,0,z> + toward*depth + right*x
    vector origin = centre - right*( w*0.5 ) + <0,0,h*0.5>
    RuiTopology_UpdatePos( board.topos[index], origin, right*max( w, 0.01 ), < 0, 0, -max( h, 0.01 ) > )
    RuiSetFloat( board.ruis[index], "basicImageAlpha", w > 0.05 && h > 0.05 ? clamp( alpha, 0.0, 1.0 ) : 0.0 )
}

void function VB_Draw( entity player )
{
    vector eye = player.EyePosition()
    entity me = GetLocalClientPlayer()
    int myVote = IsValid( me ) ? me.GetPlayerNetInt( "plVote" ) : -1
    if ( myVote != board.lastVote )
    {
        if ( board.lastVote != -2 && myVote == board.at ) board.flashAt = Time()
        board.lastVote = myVote
    }
    float t = board.openT
    float top = VB_BOTTOM + VB_H

    float settle = VB_Ease( (t-0.1)/0.38 )
    float jitter = t < 0.48 ? 2.6*sin( t*97.0 )*( 1.0 - settle ) : 0.0
    float flicker = t < 0.48 ? ( sin( t*61.0 ) > 0.2 ? 1.0 : 0.45 + 0.55*settle ) : 0.95 + 0.05*sin( Time()*23.0 )
    float move = VB_EaseInOut( (t-0.12)/0.3 )

    for ( int i = 0; i < VB_MODES; i++ )
    {
        int q = VQ_NAME + i
        entity panel = board.panels[i]
        if ( !IsValid( panel ) ) { RuiSetFloat( board.ruis[q], "basicImageAlpha", 0.0 ); continue; }
        vector toward = VB_Toward( panel, eye )
        float h = clamp( Distance( eye, panel.GetOrigin() )/55.0, 8.0, 20.0 )
        float z = VB_NAME_Z + 2.0*sin( Time()*1.6 + i )
        float w = h*board.aspect[i]
        float x = 0.0
        if ( i == board.at )
        {
            float ww = VB_NAME_H*board.aspect[i]
            h += ( VB_NAME_H - h )*move
            w += ( ww - w )*move
            z += ( top - VB_PAD - VB_NAME_H*0.5 - z )*move
            x = ( -VB_W*0.5 + VB_PAD + ww*0.5 )*move + jitter*move
        }
        RuiSetFloat3( board.ruis[q], "basicImageColor", i == myVote ? VB_GREEN : VB_ORANGE )
        VB_Quad( q, panel, toward, x, z, w, h, 1.0, i == board.at ? flicker : 1.0 )
    }
    if ( board.at < 0 || !IsValid( board.panels[board.at] ) ) return

    int i = board.at
    entity panel = board.panels[i]
    vector toward = VB_Toward( panel, eye )
    bool mine = myVote == i
    float flash = max( 0.0, 1.0 - ( Time() - board.flashAt )/0.6 )
    vector accent = mine ? VB_GREEN : VB_ORANGE
    float centreZ = VB_BOTTOM + VB_H*0.5

    float shoot = VB_Ease( t/0.16 )
    float beamTop = VB_BEAM_Z + ( VB_BOTTOM - VB_BEAM_Z )*shoot
    RuiSetFloat3( board.ruis[VQ_BEAM], "basicImageColor", accent )
    float pulse = 0.42 + 0.1*sin( Time()*4.0 )
    VB_Quad( VQ_BEAM, panel, toward, 0.0, ( VB_BEAM_Z + beamTop )*0.5, VB_W*( 0.4 + 0.6*shoot ), beamTop - VB_BEAM_Z, -0.4, ( t < 0.2 ? 0.9 : pulse + 0.3*flash )*min( 1.0, t/0.05 ) )

    float glass = VB_Ease( (t-0.12)/0.2 )
    RuiSetFloat3( board.ruis[VQ_PANEL], "basicImageColor", VB_Mix( VB_GLASS, accent*0.55, flash*0.7 ) )
    VB_Quad( VQ_PANEL, panel, toward, jitter, centreZ, VB_W, VB_H*( 0.15 + 0.85*VB_Ease( (t-0.1)/0.22 ) ), 0.0, glass*flicker )

    float snap = VB_Ease( (t-0.06)/0.24 )
    float grow = 1.32 - 0.32*snap + 0.012*sin( Time()*2.2 ) + 0.05*flash
    RuiSetFloat3( board.ruis[VQ_BRACKETS], "basicImageColor", accent )
    VB_Quad( VQ_BRACKETS, panel, toward, jitter, centreZ, ( VB_W + 6.0 )*grow, ( VB_H + 6.0 )*grow, 0.5, snap*flicker )

    float sweep = ( Time()*0.45 ) % 1.0
    RuiSetFloat3( board.ruis[VQ_SWEEP], "basicImageColor", accent )
    VB_Quad( VQ_SWEEP, panel, toward, 0.0, top - sweep*VB_H, VB_W - 4.0, 3.2, 0.3, t > 0.5 ? 0.35*sin( sweep*PI ) : 0.0 )

    float line = VB_Ease( (t-0.38)/0.25 )
    float lineW = 70.0*line
    RuiSetFloat3( board.ruis[VQ_LINE], "basicImageColor", accent )
    VB_Quad( VQ_LINE, panel, toward, -VB_W*0.5 + VB_PAD + lineW*0.5, top - VB_PAD - VB_NAME_H - 2.5, lineW, 0.45, 0.6, 0.8*line )

    int votes = minint( 99, GetGlobalNetInt( "plVotes" + i ) )
    float count = VB_Ease( (t-0.35)/0.4 )
    int shown = count >= 1.0 ? votes : int( votes*count + 0.5 )
    if ( count >= 1.0 && board.lastVotes >= 0 && votes != board.lastVotes ) board.popAt = Time()
    if ( count >= 1.0 ) board.lastVotes = votes
    float pop = max( 0.0, 1.0 - ( Time() - board.popAt )/0.35 )
    float dh = VB_DIGIT_H*( 1.0 + 0.35*pop )
    float dw = dh*VB_DIGIT_ASPECT
    float digitsZ = top - VB_PAD - VB_DIGIT_H*0.5 - 1.0
    float right = VB_W*0.5 - VB_PAD - dw*0.5
    float digits = VB_Ease( (t-0.3)/0.2 )*flicker
    RuiSetImage( board.ruis[VQ_ONES], "basicImage", PartyHolo_Digit( shown % 10 ) )
    RuiSetFloat3( board.ruis[VQ_ONES], "basicImageColor", VB_Mix( accent, <1,1,1>, pop*0.6 ) )
    VB_Quad( VQ_ONES, panel, toward, right + jitter, digitsZ, dw, dh, 0.8, digits )
    RuiSetImage( board.ruis[VQ_TENS], "basicImage", PartyHolo_Digit( ( shown/10 ) % 10 ) )
    RuiSetFloat3( board.ruis[VQ_TENS], "basicImageColor", VB_Mix( accent, <1,1,1>, pop*0.6 ) )
    VB_Quad( VQ_TENS, panel, toward, right - dw*0.82 + jitter, digitsZ, dw, dh, 0.8, shown >= 10 ? digits : 0.0 )

    VB_Quad( VQ_TEXT, panel, toward, jitter, top - VB_TEXT_H*0.5, VB_W, VB_TEXT_H, 0.6, 0.0 )
    string about = VB_Description( i )
    int typed = minint( about.len(), maxint( 0, int( (t-0.45)*70.0 ) ) )
    RuiSetString( board.texts[0], "msgText", about.slice( 0, typed ) )
    string status = mine ? "YOUR VOTE" : "USE THE SCREEN TO VOTE"
    if ( !mine && GetGlobalNetInt( "plLastMode" ) == i ) status = "JUST PLAYED"
    if ( i <= 3 ) status += "  /  PARTYPACK EXCLUSIVE"
    RuiSetString( board.texts[1], "msgText", status )
    RuiSetFloat3( board.texts[1], "msgColor", mine ? VB_GREEN : VB_DIM )
    RuiSetString( board.texts[2], "msgText", votes == 1 ? "VOTE" : "VOTES" )
    RuiSetFloat( board.texts[0], "msgAlpha", flicker )
    RuiSetFloat( board.texts[1], "msgAlpha", VB_Ease( (t-0.7)/0.25 )*flicker )
    RuiSetFloat( board.texts[2], "msgAlpha", digits )
}

asset function PartyHolo_Digit( int d )
{
    switch ( d )
    {
        case 1: return $"rui/ceaika/holo_digit_1"
        case 2: return $"rui/ceaika/holo_digit_2"
        case 3: return $"rui/ceaika/holo_digit_3"
        case 4: return $"rui/ceaika/holo_digit_4"
        case 5: return $"rui/ceaika/holo_digit_5"
        case 6: return $"rui/ceaika/holo_digit_6"
        case 7: return $"rui/ceaika/holo_digit_7"
        case 8: return $"rui/ceaika/holo_digit_8"
        case 9: return $"rui/ceaika/holo_digit_9"
    }
    return $"rui/ceaika/holo_digit_0"
}
