global function Sh_PartyLobby_Init
global function PartyLobby_ModeEnabled
global const string GAMEMODE_PARTYLOBBY = "partylobby"

// vote ids stay stable for the bridge + transition cards. these two slots cant win
bool function PartyLobby_ModeEnabled( int index )
{
    return index >= 0 && index < 11 && index != 5 && index != 7
}

// party lobby: vote at the screens, ready up, lobby launches the match
void function Sh_PartyLobby_Init()
{
    AddCallback_OnCustomGamemodesInit( PartyLobby_Create )
    AddCallback_OnRegisteringCustomNetworkVars( PartyLobby_Network )
}

void function PartyLobby_Create()
{
    GameMode_Create( GAMEMODE_PARTYLOBBY )
    GameMode_SetName( GAMEMODE_PARTYLOBBY, "#GAMEMODE_PARTYLOBBY" )
    GameMode_SetDesc( GAMEMODE_PARTYLOBBY, "#PL_partylobby_desc" )
    GameMode_SetGameModeAnnouncement( GAMEMODE_PARTYLOBBY, "ffa_modeDesc" )
    GameMode_SetDefaultTimeLimits( GAMEMODE_PARTYLOBBY, 9999, 0.0 )
    GameMode_SetDefaultScoreLimits( GAMEMODE_PARTYLOBBY, 999, 0 )
    GameMode_AddScoreboardColumnData( GAMEMODE_PARTYLOBBY, "#SCOREBOARD_SCORE", PGS_ASSAULT_SCORE, 2 )
    GameMode_SetColor( GAMEMODE_PARTYLOBBY, [ 253, 75, 1, 255 ] )
    #if SERVER
        GameMode_AddServerInit( GAMEMODE_PARTYLOBBY, PartyLobby_Init )
        GameMode_SetPilotSpawnpointsRatingFunc( GAMEMODE_PARTYLOBBY, RateSpawnpoints_Generic )
        GameMode_SetTitanSpawnpointsRatingFunc( GAMEMODE_PARTYLOBBY, RateSpawnpoints_Generic )
    #elseif CLIENT
        GameMode_AddClientInit( GAMEMODE_PARTYLOBBY, Cl_PartyLobby_Init )
    #endif
    #if !UI
        GameMode_SetScoreCompareFunc( GAMEMODE_PARTYLOBBY, CompareAssaultScore )
    #endif
}

void function PartyLobby_Network()
{
    // match end + lobby transitions show in every party mode
    Remote_RegisterFunction( "PartyTransition" )
    if ( GAMETYPE != GAMEMODE_PARTYLOBBY ) return
    // votes per mode in the lobby's order
    for ( int i = 0; i < 11; i++ )
        RegisterNetworkedVariable( "plVotes" + i, SNDC_GLOBAL, SNVT_INT, 0 )
    // 0 until majority ready, then the launch time
    RegisterNetworkedVariable( "plDeadline", SNDC_GLOBAL, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable( "plCountdownTotal", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "plReadyCount", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "plPlayerCount", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "plChosen", SNDC_GLOBAL, SNVT_INT, -1 )
    RegisterNetworkedVariable( "plLastMode", SNDC_GLOBAL, SNVT_INT, -1 )
    RegisterNetworkedVariable( "plReady", SNDC_PLAYER_GLOBAL, SNVT_BOOL, false )
    RegisterNetworkedVariable( "plVote", SNDC_PLAYER_GLOBAL, SNVT_INT, -1 )
    RegisterNetworkedVariable( "plHoldStart", SNDC_PLAYER_EXCLUSIVE, SNVT_TIME, 0.0 )
}
