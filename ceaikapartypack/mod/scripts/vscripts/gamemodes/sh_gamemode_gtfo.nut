global function Sh_GTFO_Init
global function GTFO_CanExecute
global function GTFO_Corners
global function GTFO_Center
global function GTFO_Inside
global function GTFO_Floor
global function GTFO_LowestIndices
global function GTFO_Radius
global function GTFO_GetTime
global const string GAMEMODE_GTFO = "gtfo"

void function Sh_GTFO_Init()
{
    AddCallback_OnCustomGamemodesInit( GTFO_Create )
    AddCallback_OnRegisteringCustomNetworkVars( GTFO_Network )
}

void function GTFO_Create()
{
    GameMode_Create( GAMEMODE_GTFO )
    GameMode_SetName( GAMEMODE_GTFO, "#GAMEMODE_GTFO" )
    GameMode_SetDesc( GAMEMODE_GTFO, "#PL_gtfo_desc" )
    GameMode_SetGameModeAnnouncement( GAMEMODE_GTFO, "ffa_modeDesc" )
    GameMode_SetIcon( GAMEMODE_GTFO, $"ui/menu/playlist/tdm" )
    GameMode_SetDefaultTimeLimits( GAMEMODE_GTFO, 9999, 0.0 )
    GameMode_SetDefaultScoreLimits( GAMEMODE_GTFO, 3, 0 )
    GameMode_AddScoreboardColumnData( GAMEMODE_GTFO, "#HP_SCOREBOARD_WINS", PGS_ASSAULT_SCORE, 2 )
    GameMode_AddScoreboardColumnData( GAMEMODE_GTFO, "#GTFO_SECONDS", PGS_DEFENSE_SCORE, 2 )
    GameMode_SetColor( GAMEMODE_GTFO, [ 70, 235, 190, 255 ] )
    AddPrivateMatchMode( GAMEMODE_GTFO )
    #if SERVER
        GameMode_AddServerInit( GAMEMODE_GTFO, GamemodeFFAShared_Init )
        GameMode_AddServerInit( GAMEMODE_GTFO, GTFO_Init )
        GameMode_SetPilotSpawnpointsRatingFunc( GAMEMODE_GTFO, RateSpawnpoints_Generic )
        GameMode_SetTitanSpawnpointsRatingFunc( GAMEMODE_GTFO, RateSpawnpoints_Generic )
    #elseif CLIENT
        GameMode_AddClientInit( GAMEMODE_GTFO, GamemodeFFAShared_Init )
        GameMode_AddClientInit( GAMEMODE_GTFO, ClGamemodeFFA_Init )
        GameMode_AddClientInit( GAMEMODE_GTFO, Cl_GTFO_Init )
    #endif
    #if !UI
        GameMode_SetScoreCompareFunc( GAMEMODE_GTFO, CompareAssaultScore )
    #endif
}

void function GTFO_Network()
{
    if ( GAMETYPE != GAMEMODE_GTFO ) return
    Remote_RegisterFunction( "GTFO_LaserShotFX" )
    // State: waiting, intermission, live. Replicated state also covers late joins.
    RegisterNetworkedVariable( "gtfoState", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "gtfoRound", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "gtfoHill", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "gtfoAlive", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "gtfoDeadline", SNDC_GLOBAL, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable( "gtfoTarget", SNDC_GLOBAL, SNVT_ENTITY )
    // Stock integer netvars are small. Pack centiseconds into three bytes,
    // like Frontier Defense money, so long rounds keep their full precision.
    RegisterNetworkedVariable( "gtfoTime", SNDC_PLAYER_GLOBAL, SNVT_UNSIGNED_INT, 0 )
    RegisterNetworkedVariable( "gtfoTime256", SNDC_PLAYER_GLOBAL, SNVT_UNSIGNED_INT, 0 )
    RegisterNetworkedVariable( "gtfoTime65536", SNDC_PLAYER_GLOBAL, SNVT_UNSIGNED_INT, 0 )
    RegisterNetworkedVariable( "gtfoInRound", SNDC_PLAYER_GLOBAL, SNVT_BOOL, false )
    RegisterNetworkedVariable( "gtfoOut", SNDC_PLAYER_GLOBAL, SNVT_BOOL, true )
    RegisterNetworkedVariable( "gtfoScoring", SNDC_PLAYER_EXCLUSIVE, SNVT_BOOL, false )
}

bool function GTFO_CanExecute( entity attacker, entity target ) { return false; }

int function GTFO_GetTime( entity player )
{
    return player.GetPlayerNetInt( "gtfoTime" ) + 256*player.GetPlayerNetInt( "gtfoTime256" ) + 65536*player.GetPlayerNetInt( "gtfoTime65536" )
}

// User-authored Angel City presets; their averaged centers locate the domes.
array<vector> function GTFO_Corners( int hill )
{
    switch ( hill )
    {
        case 1: return [ <1438,561,804>, <908,566,804>, <916,1132,804>, <1435,1124,804> ]
        case 2: return [ <50.11,218,776>, <366,217,776>, <361,-91,776>, <46,-92,776> ]
    }
    return [ < -1470,1468,1028>, < -1470,1158,1028>, < -1784,1158,1028>, < -1784,1468,1028> ]
}

vector function GTFO_Center( int hill )
{
    vector center = <0,0,0>
    foreach ( vector corner in GTFO_Corners( hill ) ) center += corner
    return center / 4.0
}

// The supplied z values are the wall bases, not the floor. Roof heights for
// scoring/spawns were measured with world traces on mp_angel_city.
float function GTFO_Floor( int hill )
{
    if ( hill == 1 ) return 738.0
    if ( hill == 2 ) return 708.0
    return 960.0
}

// Use the stock Titan bubble's radius for both its visual and scoring volume.
float function GTFO_Radius() { return float(TITAN_BUBBLE_SHIELD_INVULNERABILITY_RANGE); }

bool function GTFO_Inside( vector pos, int hill )
{
    vector center = GTFO_Center(hill)
    center.z = GTFO_Floor(hill)
    vector offset = pos-center
    if ( offset.z < -8.0 ) return false
    offset.z = max(0.0,offset.z)
    return DotProduct(offset,offset) <= GTFO_Radius()*GTFO_Radius()
}

array<int> function GTFO_LowestIndices( array<int> times )
{
    array<int> lowest
    int minimum = 2147483647
    foreach ( int index, int seconds in times )
    {
        if ( seconds < minimum ) { minimum = seconds; lowest.clear(); }
        if ( seconds == minimum ) lowest.append( index )
    }
    return lowest
}
