global function Sh_BodySwap_Init
global const string GAMEMODE_BODYSWAP = "bodyswap"

void function Sh_BodySwap_Init()
{
    AddCallback_OnCustomGamemodesInit( BodySwap_Create )
    AddCallback_OnRegisteringCustomNetworkVars( BodySwap_Network )
}

void function BodySwap_Network()
{
    if ( GAMETYPE != GAMEMODE_BODYSWAP ) return

    RegisterNetworkedVariable( "bsNextSwap", SNDC_GLOBAL, SNVT_TIME, 0.0 )
}

void function BodySwap_Create()
{
    GameMode_Create( GAMEMODE_BODYSWAP )
    GameMode_SetName( GAMEMODE_BODYSWAP, "#GAMEMODE_BODYSWAP" )
    GameMode_SetDesc( GAMEMODE_BODYSWAP, "#PL_bodyswap_desc" )
    GameMode_SetGameModeAnnouncement( GAMEMODE_BODYSWAP, "phunt_modeDesc" )
    GameMode_SetIcon( GAMEMODE_BODYSWAP, $"ui/menu/playlist/tdm" )
    GameMode_SetDefaultScoreLimits( GAMEMODE_BODYSWAP, 50, 0 )
    GameMode_SetDefaultTimeLimits( GAMEMODE_BODYSWAP, 10, 0.0 )
    GameMode_AddScoreboardColumnData( GAMEMODE_BODYSWAP, "#SCOREBOARD_KILLS", PGS_PILOT_KILLS, 2 )
    GameMode_AddScoreboardColumnData( GAMEMODE_BODYSWAP, "#SCOREBOARD_TITAN_KILLS", PGS_TITAN_KILLS, 1 )
    GameMode_AddScoreboardColumnData( GAMEMODE_BODYSWAP, "#SCOREBOARD_DEATHS", PGS_DEATHS, 2 )
    GameMode_SetColor( GAMEMODE_BODYSWAP, [ 120, 90, 255, 255 ] )
    AddPrivateMatchMode( GAMEMODE_BODYSWAP )
    #if SERVER
        GameMode_AddServerInit( GAMEMODE_BODYSWAP, BodySwap_Init )
    #elseif CLIENT
        GameMode_AddClientInit( GAMEMODE_BODYSWAP, Cl_BodySwap_Init )
    #endif
    #if SERVER
        GameMode_SetPilotSpawnpointsRatingFunc( GAMEMODE_BODYSWAP, RateSpawnpoints_Generic )
        GameMode_SetTitanSpawnpointsRatingFunc( GAMEMODE_BODYSWAP, RateSpawnpoints_Generic )
    #endif
    #if !UI
        GameMode_SetScoreCompareFunc( GAMEMODE_BODYSWAP, CompareKills )
    #endif
}
