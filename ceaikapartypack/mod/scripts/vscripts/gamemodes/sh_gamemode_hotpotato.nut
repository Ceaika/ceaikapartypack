global function HP_TacticalAttack
global function HP_CanExecute
global function Sh_HotPotato_Init
global const string GAMEMODE_HOTPOTATO = "hotpotato"

void function Sh_HotPotato_Init()
{

    Party_SetWeaponHandler( "tactical", HP_TacticalAttack )
    AddCallback_OnCustomGamemodesInit( HotPotato_Create )
    AddCallback_OnRegisteringCustomNetworkVars( HP_Network )
}

void function HotPotato_Create()
{
    GameMode_Create( GAMEMODE_HOTPOTATO )
    GameMode_SetName( GAMEMODE_HOTPOTATO, "#GAMEMODE_HOTPOTATO" )
    GameMode_SetDesc( GAMEMODE_HOTPOTATO, "#PL_hotpotato_desc" )
    GameMode_SetGameModeAnnouncement( GAMEMODE_HOTPOTATO, "ffa_modeDesc" )
    GameMode_SetDefaultTimeLimits( GAMEMODE_HOTPOTATO, 9999, 0.0 )
    GameMode_SetDefaultScoreLimits( GAMEMODE_HOTPOTATO, 5, 0 )
    GameMode_AddScoreboardColumnData( GAMEMODE_HOTPOTATO, "#HP_SCOREBOARD_WINS", PGS_ASSAULT_SCORE, 2 )
    GameMode_SetColor( GAMEMODE_HOTPOTATO, [ 255, 135, 35, 255 ] )
    AddPrivateMatchMode( GAMEMODE_HOTPOTATO )
    #if SERVER
        GameMode_AddServerInit( GAMEMODE_HOTPOTATO, GamemodeFFAShared_Init )
        GameMode_AddServerInit( GAMEMODE_HOTPOTATO, HotPotato_Init )
        GameMode_SetPilotSpawnpointsRatingFunc( GAMEMODE_HOTPOTATO, RateSpawnpoints_Generic )
        GameMode_SetTitanSpawnpointsRatingFunc( GAMEMODE_HOTPOTATO, RateSpawnpoints_Generic )
    #elseif CLIENT
        GameMode_AddClientInit( GAMEMODE_HOTPOTATO, GamemodeFFAShared_Init )
        GameMode_AddClientInit( GAMEMODE_HOTPOTATO, ClGamemodeFFA_Init )
        GameMode_AddClientInit( GAMEMODE_HOTPOTATO, Cl_HotPotato_Init )
    #endif
    #if !UI
        GameMode_SetScoreCompareFunc( GAMEMODE_HOTPOTATO, CompareAssaultScore )
    #endif
}

bool function HP_CanExecute( entity attacker, entity target )
{

    return false
}

void function HP_Network()
{
    if ( GAMETYPE != GAMEMODE_HOTPOTATO ) return
    Remote_RegisterFunction( "HP_Feedback" )
    RegisterNetworkedVariable( "hpCarrier", SNDC_GLOBAL, SNVT_ENTITY )
    RegisterNetworkedVariable( "hpDrop", SNDC_GLOBAL, SNVT_ENTITY )
    RegisterNetworkedVariable( "hpDropState", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "hpDropImpact", SNDC_GLOBAL, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable( "hpTacticalClaimed", SNDC_PLAYER_EXCLUSIVE, SNVT_BOOL, false )
    RegisterNetworkedVariable( "hpTacticalSpent", SNDC_PLAYER_EXCLUSIVE, SNVT_BOOL, false )

    RegisterNetworkedVariable( "hpFuseEnd", SNDC_GLOBAL, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable( "hpRound", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "hpAlive", SNDC_GLOBAL, SNVT_INT, 0 )

    RegisterNetworkedVariable( "hpState", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "hpNextRound", SNDC_GLOBAL, SNVT_TIME, 0.0 )
}

var function HP_TacticalAttack( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    entity player = weapon.GetWeaponOwner()
    if ( !IsValid( player ) ) return 0
    bool limited = player.IsPlayer() && GAMETYPE == GAMEMODE_HOTPOTATO && weapon.HasMod( "hotpotato_single_use" )
    if ( limited && player.GetPlayerNetBool( "hpTacticalSpent" ) ) return 0
    var result = 0
    switch ( weapon.GetWeaponClassName() )
    {
        case "mp_ability_shifter":
            result = OnWeaponPrimaryAttack_shifter( weapon, attackParams )
            break
        case "mp_ability_heal":
            result = OnWeaponPrimaryAttack_ability_heal( weapon, attackParams )
            break
        case "mp_ability_grapple":
            result = OnWeaponPrimaryAttack_ability_grapple( weapon, attackParams )
            break
        case "mp_ability_holopilot":
            result = OnWeaponPrimaryAttack_holopilot( weapon, attackParams )
            break
    }
    #if SERVER
        if ( limited && result > 0 )
        {
            player.SetPlayerNetBool( "hpTacticalSpent", true )

        }
    #endif
    return result
}
