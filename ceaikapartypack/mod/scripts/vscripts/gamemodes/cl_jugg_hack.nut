untyped
global function JuggHackClientInit
global function JuggHackBegin
global function JuggHackProgress
global function JuggHackEnd

const int HACK_STEPS = 5

struct
{
    int id = 0
    array<int> sequence
    int step = 0
    float started = 0.0
    float deadline = 0.0
    float errorUntil = 0.0
    float resultUntil = 0.0
    float nextInput = 0.0
    string result = ""
    bool success = false
} hackUI

struct
{
    var cardTopo
    var card
    var barTopo
    var bar
    var fillTopo
    var fill
    var title
    var count
    var hint
    array<var> tileTopos
    array<var> tiles
    array<var> arrows
    bool created = false
} hackHud

void function JuggHackClientInit()
{
    array<int> keys=[KEY_W,KEY_UP,KEY_D,KEY_RIGHT,KEY_S,KEY_DOWN,KEY_A,KEY_LEFT]
    for(int i=0;i<keys.len();i++)
    {
        int direction=i/2
        RegisterButtonPressedCallback(keys[i],void function(entity player) : (direction) { JuggHackKey(direction) })
    }
    thread JuggHackHUD()
}

void function JuggHackBegin(int id,int code,float duration)
{
    hackUI.id=id
    hackUI.sequence.clear()
    for(int i=0;i<HACK_STEPS;i++) { hackUI.sequence.append(code%4);code=code/4; }
    hackUI.step=0
    hackUI.started=Time()
    hackUI.deadline=Time()+duration+0.5
    hackUI.errorUntil=0.0
    hackUI.resultUntil=0.0
    hackUI.nextInput=0.0
}

void function JuggHackProgress(int id,int step,bool mistake)
{
    if(hackUI.id!=id) return
    hackUI.step=step
    hackUI.errorUntil=mistake ? Time()+0.45 : 0.0
    entity player=GetLocalClientPlayer()
    if(IsValid(player)) EmitSoundOnEntity(player,mistake ? "coop_sentrygun_deploymentdeniedbeep" : "UI_InGame_FD_WaveTick")
}

void function JuggHackEnd(int id,bool success)
{
    if(hackUI.id!=id) return
    hackUI.id=0
    hackUI.success=success
    hackUI.result=success ? "ACCESS GRANTED" : "HACK INTERRUPTED"
    hackUI.resultUntil=Time()+0.9
    entity player=GetLocalClientPlayer()
    if(IsValid(player) && success) EmitSoundOnEntity(player,"UI_InGame_FD_ArmorySymbolAppear")
}

void function JuggHackKey(int direction)
{
    entity player=GetLocalClientPlayer()
    if(hackUI.id==0 || Time()>hackUI.deadline || hackUI.step>=HACK_STEPS || Time()<hackUI.nextInput) return
    if(!IsValid(player) || !IsAlive(player) || player.IsTitan() || GetGlobalNetInt("juggPhase")!=2) return
    hackUI.nextInput=Time()+0.04
    player.ClientCommand("jugg_hack_input "+hackUI.id+" "+direction)
}

var function JuggHackTopo() { return RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false) }
var function JuggHackRect(var topo,vector color,int sort)
{
    var rui=RuiCreate($"ui/basic_image.rpak",topo,RUI_DRAW_HUD,sort)
    RuiSetFloat3(rui,"basicImageColor",color)
    RuiSetFloat(rui,"basicImageAlpha",0.0)
    return rui
}
var function JuggHackText(float size)
{
    var rui=CreateFullscreenRui($"ui/cockpit_console_text_center.rpak",127)
    RuiSetInt(rui,"maxLines",1)
    RuiSetInt(rui,"lineNum",0)
    RuiSetFloat(rui,"thicken",0.0)
    RuiSetFloat(rui,"msgAlpha",0.0)
    RuiSetFloat(rui,"msgFontSize",size)
    RuiSetFloat3(rui,"msgColor",<0.9,0.96,1.0>)
    return rui
}
void function JuggHackPlace(var topo,float x,float y,float w,float h)
{
    RuiTopology_UpdatePos(topo,<x,y,0>,<w,0,0>,<0,h,0>)
}

void function JuggHackCreate()
{
    hackHud.cardTopo=JuggHackTopo()
    hackHud.card=JuggHackRect(hackHud.cardTopo,<0.01,0.012,0.018>,124)
    hackHud.barTopo=JuggHackTopo()
    hackHud.bar=JuggHackRect(hackHud.barTopo,<0.12,0.13,0.15>,125)
    hackHud.fillTopo=JuggHackTopo()
    hackHud.fill=JuggHackRect(hackHud.fillTopo,<0.25,0.86,0.78>,126)
    hackHud.title=JuggHackText(30.0)
    RuiSetFloat(hackHud.title,"thicken",0.2)
    hackHud.count=JuggHackText(18.0)
    hackHud.hint=JuggHackText(17.0)

    for(int i=0;i<HACK_STEPS;i++)
    {
        hackHud.tileTopos.append(JuggHackTopo())
        hackHud.tiles.append(JuggHackRect(hackHud.tileTopos[i],<0.1,0.11,0.13>,125))
        hackHud.arrows.append(JuggHackRect(hackHud.tileTopos[i],<1,1,1>,126))
        RuiSetImage(hackHud.arrows[i],"basicImage",$"rui/ceaika/hack_arrow")
    }
    hackHud.created=true
}

void function JuggHackDestroy()
{
    array ruis=[hackHud.card,hackHud.bar,hackHud.fill,hackHud.title,hackHud.count,hackHud.hint]
    ruis.extend(hackHud.tiles)
    ruis.extend(hackHud.arrows)
    foreach(rui in ruis) RuiDestroyIfAlive(rui)
    array topos=[hackHud.cardTopo,hackHud.barTopo,hackHud.fillTopo]
    topos.extend(hackHud.tileTopos)
    foreach(topo in topos) RuiTopology_Destroy(topo)
    hackHud.tileTopos.clear()
    hackHud.tiles.clear()
    hackHud.arrows.clear()
    hackHud.created=false
}

void function JuggHackHUD()
{
    while(!IsValid(GetLocalClientPlayer())) WaitFrame()

    OnThreadEnd(function() { if(hackHud.created) JuggHackDestroy() })
    while(true)
    {
        entity player=GetLocalClientPlayer()
        bool living=IsValid(player) && IsAlive(player) && !player.IsTitan() && GetGlobalNetInt("juggPhase")==2
        if(!living || (hackUI.id!=0 && Time()>hackUI.deadline)) hackUI.id=0
        bool active=living && hackUI.id!=0
        bool result=living && !active && Time()<hackUI.resultUntil
        if(!active && !result)
        {
            if(hackHud.created) JuggHackDestroy()
            WaitFrame()
            continue
        }
        if(!hackHud.created) JuggHackCreate()
        JuggHackDrawCard(active,result)
        for(int i=0;i<HACK_STEPS;i++) JuggHackDrawTile(i,active)
        WaitFrame()
    }
}

void function JuggHackDrawCard(bool active,bool result)
{
    float width=GetScreenSize()[0]
    float height=GetScreenSize()[1]
    float s=height/1080.0
    float w=520.0*s
    float h=(result ? 70.0 : 214.0)*s
    float x=width*0.5-w*0.5
    float y=height*0.5+70.0*s
    bool error=Time()<hackUI.errorUntil
    vector accent=error ? <1.0,0.3,0.22> : <0.25,0.86,0.78>
    if(result) accent=hackUI.success ? <0.3,0.92,0.58> : <1.0,0.3,0.22>
    float alpha=active || result ? 1.0 : 0.0
    JuggHackPlace(hackHud.cardTopo,x,y,w,h)
    RuiSetFloat(hackHud.card,"basicImageAlpha",0.8*alpha)

    float total=max(0.1,hackUI.deadline-hackUI.started)
    float left=result ? 1.0 : clamp((hackUI.deadline-Time())/total,0.0,1.0)
    JuggHackPlace(hackHud.barTopo,x,y,w,4.0*s)
    JuggHackPlace(hackHud.fillTopo,x,y,max(1.0,w*left),4.0*s)
    RuiSetFloat(hackHud.bar,"basicImageAlpha",alpha)
    RuiSetFloat3(hackHud.fill,"basicImageColor",accent)
    RuiSetFloat(hackHud.fill,"basicImageAlpha",alpha)

    RuiSetString(hackHud.title,"msgText",result ? hackUI.result : "TERMINAL OVERRIDE")
    RuiSetFloat3(hackHud.title,"msgColor",result ? accent : <0.9,0.96,1.0>)
    RuiSetFloat2(hackHud.title,"msgPos",<0,(y+(result ? 28.0 : 30.0)*s)/height-0.5,0>)
    RuiSetFloat(hackHud.title,"msgAlpha",alpha)
    string countText=hackUI.step>=HACK_STEPS ? "OVERRIDE ACCEPTED" : format("%d / %d",hackUI.step,HACK_STEPS)
    RuiSetString(hackHud.count,"msgText",countText)
    RuiSetFloat3(hackHud.count,"msgColor",hackUI.step>=HACK_STEPS ? <0.3,0.92,0.58> : <0.62,0.68,0.74>)
    RuiSetFloat2(hackHud.count,"msgPos",<0,(y+160.0*s)/height-0.5,0>)
    RuiSetFloat(hackHud.count,"msgAlpha",active ? 1.0 : 0.0)
    RuiSetString(hackHud.hint,"msgText",error ? "WRONG DIRECTION  -  SEQUENCE RESET" : "WASD or arrow keys to hack faster  -  %use% again to cancel")
    RuiSetFloat3(hackHud.hint,"msgColor",error ? <1.0,0.35,0.28> : <0.62,0.68,0.74>)
    RuiSetFloat2(hackHud.hint,"msgPos",<0,(y+188.0*s)/height-0.5,0>)
    RuiSetFloat(hackHud.hint,"msgAlpha",active ? 1.0 : 0.0)
}

void function JuggHackDrawTile(int i,bool active)
{
    float width=GetScreenSize()[0]
    float height=GetScreenSize()[1]
    float s=height/1080.0
    float size=72.0*s
    float gap=14.0*s
    float x0=width*0.5-(HACK_STEPS*size+(HACK_STEPS-1)*gap)*0.5
    float x=x0+i*(size+gap)
    float y=height*0.5+70.0*s+62.0*s
    bool error=Time()<hackUI.errorUntil

    vector tile=<0.1,0.11,0.13>
    vector arrow=<0.6,0.65,0.7>
    asset image=$"rui/ceaika/hack_arrow"
    float arrowAlpha=0.85
    if(i<hackUI.step) { tile=<0.06,0.26,0.16>; arrow=<0.3,0.92,0.58>; image=$"rui/ceaika/hack_arrow_solid"; arrowAlpha=1.0; }
    else if(i==hackUI.step) { tile=<0.3,0.22,0.06>; arrow=<1.0,0.8,0.25>; arrowAlpha=0.75+0.25*sin(Time()*9.0); }
    if(error) { tile=<0.35,0.08,0.06>; arrow=<1.0,0.35,0.28>; image=$"rui/ceaika/hack_arrow"; arrowAlpha=1.0; }
    int direction=i<hackUI.sequence.len() ? hackUI.sequence[i] : 0
    JuggHackPlaceTurned(hackHud.tileTopos[i],x,y,size,direction)
    RuiSetFloat3(hackHud.tiles[i],"basicImageColor",tile)
    RuiSetFloat(hackHud.tiles[i],"basicImageAlpha",active ? 1.0 : 0.0)
    RuiSetImage(hackHud.arrows[i],"basicImage",image)
    RuiSetFloat3(hackHud.arrows[i],"basicImageColor",arrow)
    RuiSetFloat(hackHud.arrows[i],"basicImageAlpha",active ? arrowAlpha : 0.0)
}

void function JuggHackPlaceTurned(var topo,float x,float y,float size,int direction)
{
    if(direction==1) RuiTopology_UpdatePos(topo,<x+size,y,0>,<0,size,0>,< -size,0,0>)
    else if(direction==2) RuiTopology_UpdatePos(topo,<x+size,y+size,0>,< -size,0,0>,<0,-size,0>)
    else if(direction==3) RuiTopology_UpdatePos(topo,<x,y+size,0>,<0,-size,0>,<size,0,0>)
    else RuiTopology_UpdatePos(topo,<x,y,0>,<size,0,0>,<0,size,0>)
}

vector function JuggHackRotate(vector point,int direction)
{
    if(direction==1) return < -point.y,point.x,0>
    if(direction==2) return < -point.x,-point.y,0>
    if(direction==3) return <point.y,-point.x,0>
    return point
}
