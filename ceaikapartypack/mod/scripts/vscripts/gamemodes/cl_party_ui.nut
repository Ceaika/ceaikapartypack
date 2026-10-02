untyped
global function PartyUI_Init
global function PartyUI_Banner
global function PartyUI_Feed
global function PartyUI_Popup
global function PartyUI_BannerShowing
global function PartyUI_NoteBanner

const int PARTY_FEED_MAX = 5
const float PARTY_FEED_LIFE = 7.0

global const int PARTY_POPUP_INFO = 0
global const int PARTY_POPUP_ERROR = 1
global const int PARTY_POPUP_GOOD = 2
global const int PARTY_POPUP_ALERT = 3

struct PartyBannerData
{
    string title
    string subtitle
    vector color
    float duration
}
struct PartyFeedData
{
    string head
    string body
    vector color
    float born
}
struct PartyPopupData
{
    string title
    string subtitle
    vector color
    int kind
    float duration
}
struct
{
    array<PartyPopupData> popups
    array<PartyPopupData> popupNow
    float popupAt = -99.0
    var popupTopo
    var popupBack
    var popupLineTopo
    var popupLine
    var popupTitle
    var popupSub
    array<PartyBannerData> queue
    array<PartyBannerData> current
    float shownAt = -99.0
    array<PartyFeedData> feed
    bool started = false
    var bandTopo
    var band
    var lineTopo
    var line
    var title
    var subtitle
    var subtitle2
    array<var> itemTopos
    array<var> itemBacks
    array<var> stripeTopos
    array<var> stripes
    array<var> heads
    array<var> bodies
} party

void function PartyUI_Init()
{
    AddServerToClientStringCommandCallback( "party_banner", PartyUI_BannerCommand )
    AddServerToClientStringCommandCallback( "party_feed", PartyUI_FeedCommand )
    AddServerToClientStringCommandCallback( "party_popup", PartyUI_PopupCommand )
    thread PartyUI_Think()
}

string function PartyUI_Decode( string text )
{
    if ( text == "~" ) return ""
    return StringReplace( StringReplace( text, "\b", " ", true ), "\a", "%", true )
}
vector function PartyUI_Color( array<string> args, int first )
{
    return <args[first].tointeger()/255.0, args[first+1].tointeger()/255.0, args[first+2].tointeger()/255.0>
}
void function PartyUI_BannerCommand( array<string> args )
{
    if ( args.len() != 6 ) return
    PartyUI_Banner( PartyUI_Decode( args[4] ), PartyUI_Decode( args[5] ), PartyUI_Color( args, 0 ), args[3].tofloat() )
}
void function PartyUI_FeedCommand( array<string> args )
{
    if ( args.len() != 4 ) return
    PartyUI_Feed( PartyUI_Decode( args[3] ), PartyUI_Color( args, 0 ) )
}

void function PartyUI_PopupCommand( array<string> args )
{
    if ( args.len() != 7 ) return
    PartyUI_Popup( PartyUI_Decode( args[5] ), PartyUI_Decode( args[6] ), PartyUI_Color( args, 0 ), args[3].tointeger(), args[4].tofloat() )
}

void function PartyUI_Popup( string title, string subtitle, vector color, int kind = 0, float duration = 2.6 )
{
    PartyPopupData data
    data.title = title.toupper()
    data.subtitle = subtitle
    data.color = color
    data.kind = kind
    data.duration = clamp( duration, 1.2, 6.0 )

    if ( party.popupNow.len() > 0 && party.popupNow[0].title == data.title && party.popupNow[0].subtitle == data.subtitle && party.popups.len() == 0 )
    {
        party.popupAt = Time() - 0.2
        return
    }
    if ( party.popups.len() >= 3 ) party.popups.remove( 0 )
    party.popups.append( data )
}

void function PartyUI_Banner( string title, string subtitle, vector color, float duration = 4.5 )
{
    PartyBannerData data
    data.title = title.toupper()
    data.subtitle = StringReplace( subtitle, " | ", "  -  ", true )
    data.color = color
    data.duration = clamp( duration, 1.5, 10.0 )
    if ( party.queue.len() >= 4 ) party.queue.remove( 0 )
    party.queue.append( data )
}

void function PartyUI_Feed( string text, vector color )
{
    PartyFeedData item
    int cut = text.find( " | " ) == null ? -1 : expect int( text.find( " | " ) )
    item.head = cut < 0 ? text : text.slice( 0, cut )
    item.body = cut < 0 ? "" : text.slice( cut+3 )

    if ( cut < 0 && text.len() > 44 )
    {
        array<string> lines = split( PartyUI_Wrap( text, 44, 99 ), "\n" )
        if ( lines.len() > 1 && lines[0].len() < text.len() )
        {
            item.head = lines[0]
            item.body = strip( text.slice( lines[0].len() ) )
        }
    }
    item.color = color
    item.born = Time()
    party.feed.insert( 0, item )
    if ( party.feed.len() > PARTY_FEED_MAX ) party.feed.remove( party.feed.len()-1 )
}

string function PartyUI_Wrap( string text, int width, int maxLines )
{
    array<string> lines
    string current = ""
    foreach ( string paragraph in split( text, "\n" ) )
    {
        foreach ( string word in split( paragraph, " " ) )
        {
            if ( current != "" && current.len() + 1 + word.len() > width ) { lines.append( current ); current = word; }
            else current = current == "" ? word : current + " " + word
        }
        if ( current != "" ) { lines.append( current ); current = ""; }
    }
    if ( lines.len() > maxLines ) { lines.resize( maxLines ); lines[maxLines-1] += "..."; }
    string result = ""
    foreach ( int i, string line in lines ) result += (i == 0 ? "" : "\n") + line
    return result
}
int function PartyUI_Lines( string text )
{
    return text == "" ? 0 : split( text, "\n" ).len()
}

var function PartyUI_Text( asset kind, float size, int sort )
{
    var rui = CreateFullscreenRui( kind, sort )
    RuiSetInt( rui, "maxLines", 4 )
    RuiSetInt( rui, "lineNum", 0 )
    RuiSetFloat( rui, "msgFontSize", size )
    RuiSetFloat( rui, "msgAlpha", 0.0 )
    RuiSetFloat( rui, "thicken", 0.0 )
    RuiSetFloat3( rui, "msgColor", <1,1,1> )
    return rui
}
var function PartyUI_Topo() { return RuiTopology_CreatePlane( <0,0,0>, <1,0,0>, <0,1,0>, false ) }
var function PartyUI_Rect( var topo, vector color, int sort )
{
    var rui = RuiCreate( $"ui/basic_image.rpak", topo, RUI_DRAW_HUD, sort )
    RuiSetFloat3( rui, "basicImageColor", color )
    RuiSetFloat( rui, "basicImageAlpha", 0.0 )
    return rui
}
void function PartyUI_Place( var topo, float x, float y, float w, float h )
{
    RuiTopology_UpdatePos( topo, <x,y,0>, <w,0,0>, <0,h,0> )
}

void function PartyUI_Create()
{
    asset CENTER = $"ui/cockpit_console_text_center.rpak"
    asset LEFT = $"ui/cockpit_console_text_top_left.rpak"
    party.bandTopo = PartyUI_Topo()
    party.band = PartyUI_Rect( party.bandTopo, <0.01,0.012,0.018>, 130 )
    party.lineTopo = PartyUI_Topo()
    party.line = PartyUI_Rect( party.lineTopo, <1,1,1>, 131 )
    party.title = PartyUI_Text( CENTER, 40.0, 132 )
    RuiSetFloat( party.title, "thicken", 0.25 )
    party.subtitle = PartyUI_Text( CENTER, 21.0, 132 )
    party.subtitle2 = PartyUI_Text( CENTER, 21.0, 132 )
    party.popupTopo = PartyUI_Topo()
    party.popupBack = PartyUI_Rect( party.popupTopo, <0.01,0.012,0.018>, 133 )
    party.popupLineTopo = PartyUI_Topo()
    party.popupLine = PartyUI_Rect( party.popupLineTopo, <1,1,1>, 134 )
    party.popupTitle = PartyUI_Text( CENTER, 27.0, 135 )
    RuiSetFloat( party.popupTitle, "thicken", 0.2 )
    party.popupSub = PartyUI_Text( CENTER, 18.0, 135 )
    for ( int i = 0; i < PARTY_FEED_MAX; i++ )
    {
        party.itemTopos.append( PartyUI_Topo() )
        party.itemBacks.append( PartyUI_Rect( party.itemTopos[i], <0.01,0.012,0.018>, 126 ) )
        party.stripeTopos.append( PartyUI_Topo() )
        party.stripes.append( PartyUI_Rect( party.stripeTopos[i], <1,1,1>, 127 ) )
        party.heads.append( PartyUI_Text( LEFT, 18.0, 128 ) )
        party.bodies.append( PartyUI_Text( LEFT, 16.0, 128 ) )
    }
}

void function PartyUI_Think()
{
    while ( !IsValid( GetLocalClientPlayer() ) ) WaitFrame()

    while ( party.queue.len() == 0 && party.feed.len() == 0 && party.popups.len() == 0 ) WaitFrame()
    PartyUI_Create()
    OnThreadEnd( function()
    {
        array ruis = [party.band, party.line, party.title, party.subtitle, party.subtitle2, party.popupBack, party.popupLine, party.popupTitle, party.popupSub]
        ruis.extend( party.itemBacks ); ruis.extend( party.stripes ); ruis.extend( party.heads ); ruis.extend( party.bodies )
        foreach ( rui in ruis ) RuiDestroyIfAlive( rui )
        array topos = [party.bandTopo, party.lineTopo, party.popupTopo, party.popupLineTopo]
        topos.extend( party.itemTopos ); topos.extend( party.stripeTopos )
        foreach ( topo in topos ) RuiTopology_Destroy( topo )
    } )
    while ( true )
    {
        PartyUI_DrawBanner()
        PartyUI_DrawFeed()
        PartyUI_DrawPopup()
        WaitFrame()
    }
}

void function PartyUI_DrawBanner()
{

    float age = Time() - party.shownAt
    bool expired = party.current.len() == 0 || age > party.current[0].duration
    if ( party.queue.len() > 0 && (expired || age > 2.0) )
    {
        party.current.clear()
        party.current.append( party.queue[0] )
        party.queue.remove( 0 )
        party.shownAt = Time()
        age = 0.0
        printt( "[PartyUI] banner: " + party.current[0].title )
        entity player = GetLocalClientPlayer()
        if ( IsValid( player ) ) EmitSoundOnEntity( player, SFX_HUD_ANNOUNCE_QUICK )
    }
    float alpha = 0.0
    if ( party.current.len() > 0 )
    {
        alpha = min( clamp( age/0.15, 0.0, 1.0 ), clamp( (party.current[0].duration-age)/0.4, 0.0, 1.0 ) )
        float width = GetScreenSize()[0]
        float height = GetScreenSize()[1]
        float s = height / 1080.0
        string subtitle = PartyUI_Wrap( party.current[0].subtitle, 70, 2 )

        int lines = PartyUI_Lines( subtitle )
        float h = (lines == 0 ? 64.0 : 92.0 + 24.0*(lines-1))*s
        float w = 820.0*s
        float x = width*0.5 - w*0.5

        float y = height*0.27
        PartyUI_Place( party.bandTopo, x, y, w, h )
        PartyUI_Place( party.lineTopo, x, y+h-3.0*s, w, 3.0*s )
        RuiSetFloat( party.band, "basicImageAlpha", 0.78*alpha )
        RuiSetFloat3( party.line, "basicImageColor", party.current[0].color )
        RuiSetFloat( party.line, "basicImageAlpha", alpha )
        RuiSetString( party.title, "msgText", party.current[0].title )
        RuiSetFloat3( party.title, "msgColor", party.current[0].color )
        RuiSetFloat2( party.title, "msgPos", <0,(y+30.0*s)/height-0.5,0> )
        array<string> parts = split( subtitle, "\n" )
        RuiSetString( party.subtitle, "msgText", parts.len() > 0 ? parts[0] : "" )
        RuiSetFloat2( party.subtitle, "msgPos", <0,(y+64.0*s)/height-0.5,0> )
        RuiSetString( party.subtitle2, "msgText", parts.len() > 1 ? parts[1] : "" )
        RuiSetFloat2( party.subtitle2, "msgPos", <0,(y+88.0*s)/height-0.5,0> )
    }
    RuiSetFloat( party.title, "msgAlpha", alpha )
    RuiSetFloat( party.subtitle, "msgAlpha", alpha )
    RuiSetFloat( party.subtitle2, "msgAlpha", alpha )
    if ( alpha <= 0.0 ) { RuiSetFloat( party.band, "basicImageAlpha", 0.0 ); RuiSetFloat( party.line, "basicImageAlpha", 0.0 ); }
}

void function PartyUI_DrawFeed()
{
    float width = GetScreenSize()[0]
    float height = GetScreenSize()[1]
    float s = height / 1080.0
    float w = 470.0*s
    float x = width - w - 28.0*s
    float y = height*0.40
    for ( int i = 0; i < PARTY_FEED_MAX; i++ )
    {
        float alpha = 0.0
        if ( i < party.feed.len() )
        {
            float age = Time() - party.feed[i].born
            alpha = min( clamp( age/0.15, 0.0, 1.0 ), clamp( (PARTY_FEED_LIFE-age)/0.6, 0.0, 1.0 ) )
            if ( alpha > 0.0 )
            {
                string body = PartyUI_Wrap( party.feed[i].body, 52, 3 )
                float h = (38.0 + 21.0*PartyUI_Lines( body ))*s
                PartyUI_Place( party.itemTopos[i], x, y, w, h )
                PartyUI_Place( party.stripeTopos[i], x, y, 4.0*s, h )
                RuiSetFloat3( party.stripes[i], "basicImageColor", party.feed[i].color )
                RuiSetString( party.heads[i], "msgText", PartyUI_Wrap( party.feed[i].head, 44, 1 ) )
                RuiSetFloat3( party.heads[i], "msgColor", party.feed[i].color )
                RuiSetFloat2( party.heads[i], "msgPos", <(x+14.0*s)/width,(y+8.0*s)/height,0> )
                RuiSetString( party.bodies[i], "msgText", body )
                RuiSetFloat3( party.bodies[i], "msgColor", <0.86,0.89,0.93> )
                RuiSetFloat2( party.bodies[i], "msgPos", <(x+14.0*s)/width,(y+32.0*s)/height,0> )
                y += h + 6.0*s
            }
        }
        RuiSetFloat( party.itemBacks[i], "basicImageAlpha", 0.72*alpha )
        RuiSetFloat( party.stripes[i], "basicImageAlpha", alpha )
        RuiSetFloat( party.heads[i], "msgAlpha", alpha )
        RuiSetFloat( party.bodies[i], "msgAlpha", alpha )
    }
}

void function PartyUI_DrawPopup()
{
    float age = Time() - party.popupAt
    bool expired = party.popupNow.len() == 0 || age > party.popupNow[0].duration
    if ( party.popups.len() > 0 && (expired || age > 0.7) )
    {
        party.popupNow.clear()
        party.popupNow.append( party.popups[0] )
        party.popups.remove( 0 )
        party.popupAt = Time()
        age = 0.0
        printt( "[PartyUI] popup: " + party.popupNow[0].title )
        entity player = GetLocalClientPlayer()
        int kind = party.popupNow[0].kind
        string sound = kind == PARTY_POPUP_ERROR ? "coop_sentrygun_deploymentdeniedbeep" : (kind == PARTY_POPUP_GOOD ? "UI_InGame_FD_ArmorySymbolAppear" : (kind == PARTY_POPUP_INFO ? "HUD_40mm_TrackerBeep_Locked" : ""))
        if ( IsValid( player ) && sound != "" ) EmitSoundOnEntity( player, sound )
    }
    float alpha = 0.0
    if ( party.popupNow.len() > 0 )
    {
        PartyPopupData data = party.popupNow[0]
        alpha = min( clamp( age/0.12, 0.0, 1.0 ), clamp( (data.duration-age)/0.35, 0.0, 1.0 ) )
        float width = GetScreenSize()[0]
        float height = GetScreenSize()[1]
        float s = height / 1080.0

        float rise = (1.0 - clamp( age/0.12, 0.0, 1.0 )) * 10.0 * s
        float h = (data.subtitle == "" ? 50.0 : 74.0) * s
        float w = 600.0 * s
        float x = width*0.5 - w*0.5
        float y = height*0.785 + rise
        PartyUI_Place( party.popupTopo, x, y, w, h )
        PartyUI_Place( party.popupLineTopo, x, y, w, 3.0*s )
        RuiSetFloat( party.popupBack, "basicImageAlpha", 0.8*alpha )
        RuiSetFloat3( party.popupLine, "basicImageColor", data.color )
        RuiSetFloat( party.popupLine, "basicImageAlpha", alpha )
        RuiSetString( party.popupTitle, "msgText", data.title )
        RuiSetFloat3( party.popupTitle, "msgColor", data.color )
        RuiSetFloat2( party.popupTitle, "msgPos", <0,(y+26.0*s)/height-0.5,0> )
        RuiSetString( party.popupSub, "msgText", PartyUI_Wrap( data.subtitle, 64, 1 ) )
        RuiSetFloat3( party.popupSub, "msgColor", <0.88,0.9,0.94> )
        RuiSetFloat2( party.popupSub, "msgPos", <0,(y+54.0*s)/height-0.5,0> )
    }
    RuiSetFloat( party.popupTitle, "msgAlpha", alpha )
    RuiSetFloat( party.popupSub, "msgAlpha", alpha )
    if ( alpha <= 0.0 ) { RuiSetFloat( party.popupBack, "basicImageAlpha", 0.0 ); RuiSetFloat( party.popupLine, "basicImageAlpha", 0.0 ); }
}

float partyExternalBannerUntil = 0.0
void function PartyUI_NoteBanner( float duration )
{
    partyExternalBannerUntil = Time() + duration
}

bool function PartyUI_BannerShowing()
{
    if ( Time() < partyExternalBannerUntil ) return true
    if ( party.queue.len() > 0 ) return true
    return party.current.len() > 0 && Time() - party.shownAt < party.current[0].duration
}
