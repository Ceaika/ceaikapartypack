global function PH_ArenaMap
global function PH_ArenaZMin
global function PH_ArenaZMax
global function PH_ArenaDefault
global function PH_ArenaPoints
global function PH_ArenaSet
global function PH_ArenaDistance
global function PH_ArenaNearEdge
global function PH_InArena
global function PH_ArenaCross
global function PH_ArenaHull
global function PH_ArenaOrder
global function PH_ArenaSimple
global function PH_ArenaNearest
global function PH_ArenaSegmentPoint
global function PH_ArenaPolygonDistance
global function PH_WallMap
global function PH_Walls
global function PH_WallSide
global function PH_WallDistance
global function PH_WallCrossed
struct { array<vector> points } arena

bool function PH_ArenaMap()
{
    return GetMapName()=="mp_colony02" || GetMapName()=="mp_angel_city"
}
float function PH_ArenaZMin()
{
    if(GetMapName()=="mp_complex3") return 450.0
    return GetMapName()=="mp_angel_city" ? 0.0 : -128.0
}
float function PH_ArenaZMax()
{
    if(GetMapName()=="mp_complex3") return 1450.0
    return GetMapName()=="mp_angel_city" ? 1000.0 : 800.0
}
array<vector> function PH_ArenaDefault()
{
    if(GetMapName()=="mp_angel_city")
        return [<1264.72,-3928.39,0>,<3222.52,-3895.27,0>,<3313.17,-3051.52,0>,<4173.78,-3008.31,0>,<4178.70,-2296.55,0>,<3930.81,-854.74,0>,
            <3267.51,-867.25,0>,<3210.09,113.459,0>,<2583.24,113.459,0>,<2583.24,1261.33,0>,<974.936,1261.33,0>,<974.936,265.21,0>]
    return [< -1523,-1198,0>,< -518,-1145,0>,< -50,-1774,0>,<457,-1774,0>,<972.3,-2528.2,0>,<1512.7,-2561.3,0>,<1746.5,-2551.1,0>,
        <1933.7,-2587.6,0>,<1892,1128,0>,< -204.9,1155.3,0>,< -540.5,1246.9,0>,< -821.7,1068.5,0>,< -1531,989,0>]
}
array<vector> function PH_ArenaPoints()
{
    if(arena.points.len()==0) arena.points=PH_ArenaDefault()
    return clone arena.points
}
void function PH_ArenaSet(array<vector> points) { arena.points=clone points }
float function PH_ArenaCross(vector a,vector b,vector c)
{
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
}

array<vector> function PH_ArenaHull(array<vector> points)
{
    array<vector> hull
    if(points.len()<3) return hull
    int first=0
    for(int i=1;i<points.len();i++)
        if(points[i].x<points[first].x || (points[i].x==points[first].x && points[i].y<points[first].y)) first=i
    int current=first
    for(int step=0;step<=points.len();step++)
    {
        hull.append(points[current])
        int next=(current+1)%points.len()
        for(int i=0;i<points.len();i++)
        {
            if(i==current) continue
            float turn=PH_ArenaCross(points[current],points[next],points[i])
            if(turn<0.0 || (turn==0.0 && Distance2D(points[current],points[i])>Distance2D(points[current],points[next]))) next=i
        }
        current=next
        if(current==first) return hull
    }
    hull.clear()
    return hull
}

array<vector> function PH_ArenaOrder(array<vector> points)
{
    array<vector> result=clone points
    float area=0.0
    for(int i=0;i<result.len();i++)
    {
        vector a=result[i], b=result[(i+1)%result.len()]
        area+=a.x*b.y-a.y*b.x
    }
    if(area<0.0) result.reverse()
    return result
}
bool function PH_ArenaSegmentsCross(vector a,vector b,vector c,vector d)
{
    return ((PH_ArenaCross(a,b,c)>0.0)!=(PH_ArenaCross(a,b,d)>0.0)) && ((PH_ArenaCross(c,d,a)>0.0)!=(PH_ArenaCross(c,d,b)>0.0))
}

bool function PH_ArenaSimple(array<vector> points)
{
    int n=points.len()
    for(int i=0;i<n;i++)
    {
        for(int j=i+1;j<n;j++)
        {
            if(j==i+1 || (i==0 && j==n-1)) continue
            if(PH_ArenaSegmentsCross(points[i],points[(i+1)%n],points[j],points[(j+1)%n])) return false
        }
    }
    return true
}
vector function PH_ArenaSegmentPoint(vector pos,vector a,vector b)
{
    vector ab=<b.x-a.x,b.y-a.y,0>
    float t=((pos.x-a.x)*ab.x+(pos.y-a.y)*ab.y)/(ab.x*ab.x+ab.y*ab.y)
    t=max(0.0,min(1.0,t))
    return <a.x+ab.x*t,a.y+ab.y*t,0>
}

vector function PH_ArenaNearest(vector pos,array<vector> points)
{
    vector best=<0,0,0>
    float bestDistance=100000000.0
    for(int i=0;i<points.len();i++)
    {
        vector a=points[i], b=points[(i+1)%points.len()]
        if(Distance2D(a,b)<1.0) continue
        vector point=PH_ArenaSegmentPoint(pos,a,b)
        float distance=Distance2D(pos,point)
        if(distance<bestDistance) { bestDistance=distance; best=point; }
    }
    return best
}

float function PH_ArenaPolygonDistance(vector pos,array<vector> points)
{
    if(points.len()<3) return -100000.0
    bool inside=false
    float nearest=100000.0
    for(int i=0;i<points.len();i++)
    {
        vector a=points[i], b=points[(i+1)%points.len()]
        if(Distance2D(a,b)<1.0) return -100000.0
        if((a.y>pos.y)!=(b.y>pos.y) && pos.x<(b.x-a.x)*(pos.y-a.y)/(b.y-a.y)+a.x) inside=!inside
        nearest=min(nearest,Distance2D(pos,PH_ArenaSegmentPoint(pos,a,b)))
    }
    return inside ? nearest : -nearest
}
float function PH_ArenaDistance(vector pos)
{
    if(!PH_ArenaMap()) return 100000.0
    return min(PH_ArenaPolygonDistance(pos,PH_ArenaPoints()),min(pos.z-PH_ArenaZMin(),PH_ArenaZMax()-pos.z))
}
bool function PH_InArena(vector pos,float margin=0.0) { return PH_ArenaDistance(pos)>=margin }
bool function PH_ArenaNearEdge(vector pos)
{
    if(PH_WallMap()) return PH_WallDistance(pos)<220.0
    if(!PH_ArenaMap()) return false
    return PH_ArenaPolygonDistance(pos,PH_ArenaPoints())<220.0 || pos.z>PH_ArenaZMax()-96.0 || pos.z<PH_ArenaZMin()+64.0
}

bool function PH_WallMap()
{
    return GetMapName()=="mp_complex3"
}

array<vector> function PH_Walls()
{
    array<vector> raw
    if(GetMapName()=="mp_complex3")
        raw=[< -4818.53,145.97,0>,< -4840.09,-309.06,0>,< -5887.08,-1299.90,0>,< -6229.66,-1657.35,0>,< -7356.10,-3246.92,0>,< -8856.59,-2849.54,0>]
    array<vector> walls
    for(int i=0;i+1<raw.len();i+=2)
    {
        vector along=Normalize(raw[i+1]-raw[i])*16.0
        walls.append(raw[i]-along)
        walls.append(raw[i+1]+along)
    }
    return walls
}

array<vector> function PH_WallSide()
{
    if(GetMapName()=="mp_complex3")
        return [< -4818.53,2500,0>,< -4818.53,145.97,0>,< -4840.09,-309.06,0>,< -5887.08,-1299.90,0>,< -6229.66,-1657.35,0>,
            < -7356.10,-3246.92,0>,< -8856.59,-2849.54,0>,< -11000,-2849.54,0>,< -11000,2500,0>]
    return []
}
float function PH_WallDistance(vector pos)
{
    array<vector> walls=PH_Walls()
    float nearest=100000.0
    for(int i=0;i+1<walls.len();i+=2)
        nearest=min(nearest,Distance2D(pos,PH_ArenaSegmentPoint(pos,walls[i],walls[i+1])))
    return nearest
}

int function PH_WallCrossed(vector start,vector end)
{
    array<vector> walls=PH_Walls()
    for(int i=0;i+1<walls.len();i+=2)
    {
        vector a=walls[i], b=walls[i+1]
        float sideStart=PH_ArenaCross(a,b,start), sideEnd=PH_ArenaCross(a,b,end)
        if((sideStart>0.0)==(sideEnd>0.0)) continue
        if((PH_ArenaCross(start,end,a)>0.0)!=(PH_ArenaCross(start,end,b)>0.0)) return i/2
    }
    return -1
}
