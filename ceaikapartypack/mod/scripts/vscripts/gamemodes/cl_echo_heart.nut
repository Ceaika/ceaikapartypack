untyped
global function Echo_HeartClientInit
global function Echo_HeartZoneBegin
global function Echo_HeartZonePoint
global function Echo_HeartZoneCommit
struct
{
    array<vector> incoming
    array<vector> points
    bool editing=false
    bool synced=false
    array<var> panels
    array<var> topologies
} heartVisual
void function Echo_HeartZoneBegin(bool editing) { heartVisual.incoming.clear(); heartVisual.editing=editing; }
void function Echo_HeartZonePoint(float x,float y,float z)
{
    if(heartVisual.incoming.len()<16) heartVisual.incoming.append(<x,y,z>)
}
void function Echo_HeartZoneCommit() { heartVisual.points=clone heartVisual.incoming; heartVisual.synced=true; }
void function Echo_HeartClientInit()
{
    if(GetMapName()=="mp_lf_stacks") thread Echo_HeartVisualLoop()
}
void function Echo_HeartVisualLoop()
{
    var text=CreateFullscreenRui($"ui/cockpit_console_text_center.rpak",860)
    RuiSetInt(text,"maxLines",1)
    RuiSetInt(text,"lineNum",0)
    RuiSetFloat(text,"msgFontSize",28.0)
    RuiSetFloat(text,"msgAlpha",0.0)
    RuiSetFloat(text,"thicken",0.0)
    RuiSetFloat3(text,"msgColor",<1,0.25,0.15>)
    RuiSetFloat2(text,"msgPos",<0,0.36,0>)
    RuiSetString(text,"msgText","You will get a heart attack")
    var bar=null
    var barTopo=null
    table cleanup={bar=null,topo=null}
    float retryAt=0.0
    float syncAt=0.0
    OnThreadEnd(function() : (text,cleanup) {
        RuiDestroyIfAlive(text)
        if(cleanup.bar!=null) RuiDestroyIfAlive(cleanup.bar)
        if(cleanup.topo!=null) RuiTopology_Destroy(cleanup.topo)
        foreach(var panel in heartVisual.panels) RuiDestroyIfAlive(panel)
        foreach(var topo in heartVisual.topologies) RuiTopology_Destroy(topo)
    })
    while(true)
    {
        entity p=GetLocalClientPlayer()
        if(IsValid(p) && !heartVisual.synced && Time()>=syncAt)
        {
            p.ClientCommand("echo_heart_sync")
            syncAt=Time()+1.0
        }
        bool visible=IsValid(p) && IsAlive(p) && !p.IsObserver() && GetLocalViewPlayer()==p
            && GetGameState()==eGameState.Playing && GetGlobalNetInt("echoPhase")==2 && p.GetPlayerNetBool("echoActive")
        float remaining=visible ? p.GetPlayerNetTime("echoHeartDeadline")-Time() : 0.0
        RuiSetFloat(text,"msgAlpha",remaining>0.0 ? 1.0 : 0.0)
        if(bar==null && Time()>=retryAt)
        {
            try
            {
                barTopo=RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
                bar=RuiCreate($"ui/basic_image.rpak",barTopo,RUI_DRAW_HUD,860)
                cleanup.bar=bar
                cleanup.topo=barTopo
                RuiSetFloat3(bar,"basicImageColor",<1,0.15,0.05>)
            }
            catch(error) { if(barTopo!=null) RuiTopology_Destroy(barTopo); barTopo=null; retryAt=Time()+1.0; }
        }
        if(bar!=null)
        {
            float screenWidth=GetScreenSize()[0]
            float screenHeight=GetScreenSize()[1]
            float scale=screenHeight/1080.0
            float barWidth=min(480.0*scale,screenWidth*0.8)
            float barHeight=max(4.0,6.0*scale)
            vector barOrigin=<(screenWidth-barWidth)*0.5,screenHeight*0.92,0>
            RuiTopology_UpdatePos(barTopo,barOrigin,<max(0.1,barWidth*clamp(remaining/5.0,0.0,1.0)),0,0>,<0,barHeight,0>)
            RuiSetFloat(bar,"basicImageAlpha",remaining>0.0 ? 1.0 : 0.0)
        }
        // one plane per edge at the floor height, drafts stay visible between rounds for admins
        int used=0
        if(IsValid(p) && heartVisual.editing && heartVisual.points.len()>1)
        {
            int edges=heartVisual.points.len()==2 ? 1 : heartVisual.points.len()
            for(int i=0;i<edges;i++)
            {
                vector a=heartVisual.points[i]+<0,0,3>
                vector b=heartVisual.points[(i+1)%heartVisual.points.len()]+<0,0,3>
                vector along=b-a
                if(Length2D(along)<1.0) continue
                vector side=Normalize(< -along.y,along.x,0>)*5.0
                if(used==heartVisual.panels.len())
                {
                    if(Time()<retryAt) break
                    var topo
                    try { topo=RuiTopology_CreatePlane(a,along,side,true) }
                    catch(error) { retryAt=Time()+1.0; break; }
                    heartVisual.topologies.append(topo)
                    heartVisual.panels.append(RuiCreate($"ui/basic_image.rpak",topo,RUI_DRAW_WORLD,0))
                }
                if(DotProduct(CrossProduct(along,side),p.EyePosition()-a)<0.0) { a+=side; side=-side; }
                RuiTopology_UpdatePos(heartVisual.topologies[used],a,along,side)
                RuiSetFloat3(heartVisual.panels[used],"basicImageColor",heartVisual.editing ? <1,0.55,0.1> : <1,0.05,0.03>)
                RuiSetFloat(heartVisual.panels[used],"basicImageAlpha",0.95)
                used++
            }
        }
        for(int i=used;i<heartVisual.panels.len();i++) RuiSetFloat(heartVisual.panels[i],"basicImageAlpha",0.0)
        wait 0.05
    }
}
