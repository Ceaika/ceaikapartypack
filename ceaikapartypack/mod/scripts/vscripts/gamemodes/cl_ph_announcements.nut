untyped
global function PH_AnnouncementsInit
global function PH_Announcement
global function PH_Hint
struct
{
    var heading = null
    var detail = null
    float until = 0.0
    var hint = null
    float hintUntil = 0.0
} file
void function PH_AnnouncementsInit()
{
    file.heading=CreateFullscreenRui($"ui/cockpit_console_text_center.rpak",130)
    file.detail=CreateFullscreenRui($"ui/cockpit_console_text_center.rpak",130)
    foreach(var panel in [file.heading,file.detail])
    {
        RuiSetInt(panel,"maxLines",2)
        RuiSetInt(panel,"lineNum",0)
        RuiSetFloat(panel,"msgAlpha",0.0)
        RuiSetFloat(panel,"thicken",0.0)
    }
    RuiSetFloat(file.heading,"msgFontSize",42.0)
    RuiSetFloat(file.detail,"msgFontSize",23.0)
    RuiSetFloat2(file.heading,"msgPos",<0,-0.34,0>)
    RuiSetFloat2(file.detail,"msgPos",<0,-0.28,0>)
    RuiSetFloat3(file.detail,"msgColor",<1,1,1>)
    file.hint=CreateFullscreenRui($"ui/cockpit_console_text_center.rpak",125)
    RuiSetInt(file.hint,"maxLines",2)
    RuiSetInt(file.hint,"lineNum",0)
    RuiSetFloat(file.hint,"msgFontSize",28.0)
    RuiSetFloat(file.hint,"msgAlpha",0.0)
    RuiSetFloat(file.hint,"thicken",0.0)
    RuiSetFloat3(file.hint,"msgColor",<1.0,0.85,0.45>)
    RuiSetFloat2(file.hint,"msgPos",<0,0.27,0>)
    thread PH_AnnouncementFade()
}
void function PH_Announcement(int event,int team)
{
    entity p=GetLocalClientPlayer()
    if(!IsValid(p) || file.heading==null) return
    string title=""
    string detail=""
    vector color=<0.35,1.0,0.8>
    if(event==0)
    {
        bool prop=p.GetTeam()==team
        title=prop ? "YOU ARE A PROP" : "YOU ARE A HUNTER"
        detail=prop ? "Find a hiding spot before the hunters are released." : "Wait while the props hide. Your hunt starts soon."
        if(!prop) color=<1.0,0.78,0.30>
    }
    else if(event==1)
    {
        bool prop=p.GetTeam()==team
        title=prop ? "HUNTERS RELEASED" : "HUNTERS, SEEK!"
        detail=prop ? "Stay hidden. Survive until time runs out. Every hunter miss costs them 10 seconds." : "Find the props. Every miss takes 10 seconds off the clock: choose your shots."
        color=<1.0,0.78,0.30>
    }
    else if(event==2 || event==4)
    {
        if(team==0) { title="ROUND RESET"; detail="Not enough players remain. No point awarded."; }
        else
        {
            bool won=p.GetTeam()==team
            title=(event==4 ? "MATCH " : "ROUND ")+(won ? "VICTORY" : "DEFEAT")
            detail=(team==GetGlobalNetInt("phPropTeam") ? "Props win." : "Hunters win.")+(event==4 ? " Thanks for playing Prop Hunt." : " Teams swap roles next round.")
            color=won ? <0.35,1.0,0.8> : <1.0,0.40,0.35>
        }
    }
    else if(event==3)
    {
        title="YOU WERE ELIMINATED"
        detail="Watch your team. You return next round."
        color=<1.0,0.40,0.35>
    }
    else return
    RuiSetString(file.heading,"msgText",title)
    RuiSetString(file.detail,"msgText",detail)
    RuiSetFloat3(file.heading,"msgColor",color)
    file.until=Time()+(event==4 ? 8.0 : 5.0)
    PartyUI_NoteBanner(file.until-Time())
    EmitSoundOnEntity(p,SFX_HUD_ANNOUNCE_QUICK)
}
void function PH_AnnouncementFade()
{
    OnThreadEnd(void function() { RuiDestroyIfAlive(file.heading); RuiDestroyIfAlive(file.detail); RuiDestroyIfAlive(file.hint); })
    while(true)
    {
        float alpha=clamp((file.until-Time())/0.4,0.0,1.0)
        RuiSetFloat(file.heading,"msgAlpha",alpha)
        RuiSetFloat(file.detail,"msgAlpha",alpha)
        entity p=GetLocalClientPlayer()
        bool show=IsValid(p) && IsAlive(p) && GetGlobalNetInt("phPhase")==2 && p.GetTeam()!=GetGlobalNetInt("phPropTeam")
        RuiSetFloat(file.hint,"msgAlpha",show ? clamp((file.hintUntil-Time())/0.3,0.0,1.0) : 0.0)
        wait 0.05
    }
}

void function PH_Hint(float x,float y,float z)
{
    vector source=<x,y,z>
    entity p=GetLocalClientPlayer()
    if(!IsValid(p) || !IsAlive(p) || file.hint==null || GetGlobalNetInt("phPhase")!=2 || p.GetTeam()==GetGlobalNetInt("phPropTeam")) return
    vector delta=source-p.EyePosition()
    float distance=Length(delta)
    vector forward=AnglesToForward(<0,p.EyeAngles().y,0>)
    vector right=AnglesToForward(<0,p.EyeAngles().y-90,0>)
    float ahead=DotProduct(delta,forward)
    float side=DotProduct(delta,right)
    string direction=fabs(side)>fabs(ahead) ? (side>0 ? "RIGHT" : "LEFT") : (ahead>=0 ? "AHEAD" : "BEHIND")
    string range=distance<400 ? "NEAR" : (distance<1200 ? "MID-RANGE" : "FAR")
    string height=fabs(delta.z)>160 ? (delta.z>0 ? " / ABOVE" : " / BELOW") : ""
    RuiSetString(file.hint,"msgText","PROP SOUND: "+direction+" / "+range+height)
    file.hintUntil=Time()+1.6
}
