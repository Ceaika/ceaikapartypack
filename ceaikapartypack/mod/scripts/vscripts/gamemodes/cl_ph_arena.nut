global function PH_ArenaVisualInit
global function PH_ZoneBegin
global function PH_ZonePoint
global function PH_ZoneCommit

const int PH_ARENA_MAX_EDGES = 5
struct
{
    array<vector> incoming
    array<vector> preview
    bool incomingPreview=false
    bool editing=false
    bool synced=false
    array<var> panels
    array<var> topologies
    int used=0
    float retryAt=0.0
} arenaVisual
void function PH_ZoneBegin(bool preview) { arenaVisual.incoming.clear(); arenaVisual.incomingPreview=preview }
void function PH_ZonePoint(float x,float y)
{
    if(arenaVisual.incoming.len()<16) arenaVisual.incoming.append(<x,y,0>)
}
void function PH_ZoneCommit()
{
    arenaVisual.synced=true
    arenaVisual.editing=arenaVisual.incomingPreview
    if(arenaVisual.editing) arenaVisual.preview=clone arenaVisual.incoming
    else PH_ArenaSet(arenaVisual.incoming)
}
void function PH_ArenaVisualInit()
{
    if(PH_ArenaMap() || PH_WallMap()) thread PH_ArenaVisualLoop()
}
void function PH_ArenaPanel(vector origin,vector right,vector up,float alpha,vector colour,entity p)
{
    if(DotProduct(CrossProduct(right,up),p.EyePosition()-origin)<0.0) { origin+=up; up=-up; }
    int index=arenaVisual.used
    if(index==arenaVisual.panels.len())
    {

        if(Time()<arenaVisual.retryAt) return
        var topo
        try { topo=RuiTopology_CreatePlane(origin,right,up,true) }
        catch(ex) { arenaVisual.retryAt=Time()+1.0; return }
        var panel=RuiCreate($"ui/basic_image.rpak",topo,RUI_DRAW_WORLD,0)
        arenaVisual.topologies.append(topo)
        arenaVisual.panels.append(panel)
    }
    RuiTopology_UpdatePos(arenaVisual.topologies[index],origin,right,up)
    RuiSetFloat3(arenaVisual.panels[index],"basicImageColor",colour)
    RuiSetFloat(arenaVisual.panels[index],"basicImageAlpha",alpha)
    arenaVisual.used++
}

array<int> function PH_ArenaNearestEdges(vector pos,array<vector> points,int count)
{
    array<float> distance
    for(int i=0;i<points.len();i++)
    {
        vector a=points[i],b=points[(i+1)%points.len()]
        distance.append(Distance2D(a,b)<1.0 ? 100000000.0 : Distance2D(pos,PH_ArenaSegmentPoint(pos,a,b)))
    }
    array<int> result
    while(result.len()<count && result.len()<points.len())
    {
        int best=-1
        for(int i=0;i<points.len();i++)
            if(!result.contains(i) && (best<0 || distance[i]<distance[best])) best=i
        result.append(best)
    }
    return result
}

void function PH_ArenaCurtain(vector a,vector b,vector colour,entity p)
{
    vector along=b-a
    if(Length(along)<1.0) return
    float bottom=PH_ArenaZMin()
    float height=PH_ArenaZMax()-bottom
    PH_ArenaPanel(a+<0,0,bottom>,along,<0,0,height>,0.16,colour,p)
    foreach(float f in [0.138,0.276,0.552,0.828,0.987])
        PH_ArenaPanel(a+<0,0,bottom+height*f>,along,<0,0,12>,0.95,colour,p)
    PH_ArenaPanel(a+<0,0,bottom>,Normalize(along)*12.0,<0,0,height>,0.95,colour,p)
}
void function PH_ArenaVisualLoop()
{
    while(!IsValid(GetLocalClientPlayer())) WaitFrame()

    while(!arenaVisual.synced && !PH_WallMap())
    {
        GetLocalClientPlayer().ClientCommand("ph_zone_sync")
        wait 1.0
    }
    OnThreadEnd(function()
    {
        foreach(var panel in arenaVisual.panels) RuiDestroyIfAlive(panel)
        foreach(var topo in arenaVisual.topologies) RuiTopology_Destroy(topo)
    })
    while(true)
    {
        entity p=GetLocalViewPlayer()
        arenaVisual.used=0
        if(IsValid(p))
        {
            vector colour=arenaVisual.editing ? <1,0.55,0.1> : <1,0.05,0.03>
            if(PH_WallMap())
            {

                array<vector> walls=PH_Walls()
                float bottom=PH_ArenaZMin()
                float height=PH_ArenaZMax()-bottom
                for(int i=0;i+1<walls.len();i+=2)
                {
                    PH_ArenaCurtain(walls[i],walls[i+1],colour,p)
                    PH_ArenaPanel(walls[i+1]+<0,0,bottom>,Normalize(walls[i]-walls[i+1])*12.0,<0,0,height>,0.95,colour,p)
                }
            }
            else
            {
                array<vector> points=arenaVisual.editing ? PH_ArenaOrder(arenaVisual.preview) : PH_ArenaPoints()
                foreach(int i in PH_ArenaNearestEdges(p.GetOrigin(),points,PH_ARENA_MAX_EDGES))
                    PH_ArenaCurtain(points[i],points[(i+1)%points.len()],colour,p)
            }
        }
        for(int i=arenaVisual.used;i<arenaVisual.panels.len();i++) RuiSetFloat(arenaVisual.panels[i],"basicImageAlpha",0.0)
        wait 0.05
    }
}
