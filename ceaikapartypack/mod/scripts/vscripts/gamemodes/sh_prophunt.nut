global function PH_ModelHealth
global function PH_ModelClearance
global function PH_HullClass
global function PH_ModelHull
global function PH_ModelOrigin
global function PH_RerollsLeft
global function PH_DecoysLeft
global function PH_ModelIndex
global function PH_SharedInit
global function PH_CanExecute
global const string GAMEMODE_PROPHUNT = "prophunt"

global const int PH_FB_DENY = 0
global const int PH_FB_REROLL = 1
global const int PH_FB_DECOY = 2
global const int PH_FB_LOCK = 3
global const int PH_FB_FREEZE = 4
global const int PH_FB_TAUNT = 5
global const int PH_FB_CUE = 6
global const int PH_FB_DECOY_BROKEN = 7
global const int PH_FB_MISS = 8
void function PH_SharedInit()
{
    AddCallback_OnCustomGamemodesInit( PH_Create )
    AddCallback_OnRegisteringCustomNetworkVars( PH_Network )
}
void function PH_Create()
{
    GameMode_Create( GAMEMODE_PROPHUNT )
    GameMode_SetName( GAMEMODE_PROPHUNT, "#GAMEMODE_PROPHUNT" )
    GameMode_SetDesc( GAMEMODE_PROPHUNT, "#PL_prophunt_desc" )
    GameMode_SetGameModeAnnouncement( GAMEMODE_PROPHUNT, "tdm_modeDesc" )
    GameMode_SetDefaultTimeLimits( GAMEMODE_PROPHUNT, 9999, 0.0 )
    GameMode_SetDefaultScoreLimits( GAMEMODE_PROPHUNT, 4, 0 )
    GameMode_AddScoreboardColumnData( GAMEMODE_PROPHUNT, "#PH_SCOREBOARD_ELIMS", PGS_KILLS, 2 )
    GameMode_SetColor( GAMEMODE_PROPHUNT, [70,200,160,255] )
    AddPrivateMatchMode( GAMEMODE_PROPHUNT )
    #if !UI
        GameMode_SetScoreCompareFunc( GAMEMODE_PROPHUNT, CompareKills )
    #endif
    #if SERVER
        GameMode_AddServerInit( GAMEMODE_PROPHUNT, PH_Init )
        GameMode_SetPilotSpawnpointsRatingFunc( GAMEMODE_PROPHUNT, RateSpawnpoints_Generic )
        GameMode_SetTitanSpawnpointsRatingFunc( GAMEMODE_PROPHUNT, RateSpawnpoints_Generic )
    #elseif CLIENT
        GameMode_AddClientInit( GAMEMODE_PROPHUNT, PH_ClientInit )
    #endif
}
bool function PH_CanExecute( entity attacker, entity target ) { return false }
void function PH_Network()
{
    if ( GAMETYPE != GAMEMODE_PROPHUNT ) return
    Remote_RegisterFunction("PH_Announcement")
    Remote_RegisterFunction("PH_Hint")
    Remote_RegisterFunction("PH_Feedback")
    Remote_RegisterFunction("PH_ZoneBegin")
    Remote_RegisterFunction("PH_ZonePoint")
    Remote_RegisterFunction("PH_ZoneCommit")
    RegisterNetworkedVariable( "phDebug", SNDC_GLOBAL, SNVT_BOOL, false )
    RegisterNetworkedVariable( "phPhase", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "phRound", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "phPropTeam", SNDC_GLOBAL, SNVT_INT, TEAM_MILITIA )
    RegisterNetworkedVariable( "phEnd", SNDC_GLOBAL, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable( "phWinner", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "phAlive", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "phFrozen", SNDC_PLAYER_GLOBAL, SNVT_BOOL, false )
    RegisterNetworkedVariable( "phBody", SNDC_PLAYER_GLOBAL, SNVT_ENTITY )
    RegisterNetworkedVariable( "phDisguised", SNDC_PLAYER_EXCLUSIVE, SNVT_BOOL, false )
    RegisterNetworkedVariable( "phInventory", SNDC_PLAYER_EXCLUSIVE, SNVT_INT, 0 )
    RegisterNetworkedVariable( "phLocked", SNDC_PLAYER_EXCLUSIVE, SNVT_BOOL, false )
    RegisterNetworkedVariable( "phTauntReady", SNDC_PLAYER_EXCLUSIVE, SNVT_TIME, 0.0 )
}

int function PH_RerollsLeft( entity p ) { return p.GetPlayerNetInt("phInventory") % 4; }
int function PH_DecoysLeft( entity p ) { return p.GetPlayerNetInt("phInventory") / 4; }
int function PH_ModelIndex( entity p )
{
    entity body=p.GetPlayerNetEnt("phBody")
    if (!IsValid(body)) return 0
    array<asset> models = PH_MapModels()
    for(int i=0;i<models.len();i++) if(models[i]==body.GetModelName()) return i
    return 0
}

vector function PH_ModelOrigin( entity body, vector feet, vector angles )
{
    vector low = body.GetBoundingMins()
    vector high = body.GetBoundingMaxs()
    vector offset = < -(low.x+high.x)*0.5, -(low.y+high.y)*0.5, -low.z>

    asset model=body.GetModelName()
    if(model==$"models/containers/news_stand.mdl" || model==$"models/containers/news_stand_with_graffiti.mdl")
        offset.z-=1.25
    return feet + AnglesToForward( angles )*offset.x - AnglesToRight( angles )*offset.y + <0,0,offset.z>
}
vector function PH_ModelHull( int index )
{
    array<vector> hulls = [<6,6,10>,<11,11,26>,<16,16,33>]
    return hulls[PH_HullClass(index)]
}
int function PH_HullClass( int index )
{
    array<int> classes = PH_MapClasses()
    return classes[index]
}
vector function PH_ModelClearance(int index)
{
    array<vector> sizes = PH_MapSizes()
    return sizes[index]
}

int function PH_ModelHealth(int index)
{
    array<int> health = PH_MapHealth()
    return health[index]
}
