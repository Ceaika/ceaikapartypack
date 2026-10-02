global function Sh_GamemodeJugg_Init
global function Jugg_OnSmokeAttack
global function Jugg_OnUpgradeCoreAttack
global function JuggGetHealthNet

global const string GAMEMODE_JUGG = "jugg"

struct
{
    table<entity,float> upgradeReadyAt
} juggCore

void function Sh_GamemodeJugg_Init()
{

    Party_SetWeaponHandler( "smoke", Jugg_OnSmokeAttack )
    Party_SetWeaponHandler( "upgradecore", Jugg_OnUpgradeCoreAttack )
	AddCallback_OnCustomGamemodesInit( CreateGamemodeJugg )
	AddCallback_OnRegisteringCustomNetworkVars( JuggRegisterNetworkVars )
}

void function CreateGamemodeJugg()
{
	GameMode_Create( GAMEMODE_JUGG )
	GameMode_SetName( GAMEMODE_JUGG, "#GAMEMODE_JUGG" )
	GameMode_SetDesc( GAMEMODE_JUGG, "#PL_jugg_desc" )
	GameMode_SetGameModeAnnouncement( GAMEMODE_JUGG, "ffa_modeDesc" )
	GameMode_SetDefaultTimeLimits( GAMEMODE_JUGG, 9999, 0.0 )
	GameMode_AddScoreboardColumnData( GAMEMODE_JUGG, "#SCOREBOARD_SCORE", PGS_ASSAULT_SCORE, 3 )
	GameMode_AddScoreboardColumnData( GAMEMODE_JUGG, "#JUGG_SCOREBOARD_DAMAGE", PGS_DEFENSE_SCORE, 4 )
	GameMode_SetColor( GAMEMODE_JUGG, [ 224, 112, 48, 255 ] )

	AddPrivateMatchMode( GAMEMODE_JUGG )

	#if SERVER
		GameMode_AddServerInit( GAMEMODE_JUGG, GamemodeJugg_Init )
		GameMode_SetPilotSpawnpointsRatingFunc( GAMEMODE_JUGG, JuggRatePilotSpawns )
		GameMode_SetTitanSpawnpointsRatingFunc( GAMEMODE_JUGG, RateSpawnpoints_Generic )
	#endif
	#if CLIENT
		GameMode_AddClientInit( GAMEMODE_JUGG, Cl_GamemodeJugg_Init )
	#endif
	#if !UI
		GameMode_SetScoreCompareFunc( GAMEMODE_JUGG, CompareAssaultScore )
	#endif
}

void function JuggRegisterNetworkVars()
{
    if ( GAMETYPE != GAMEMODE_JUGG )
        return
    RegisterNetworkedVariable("juggSabotageEnd",SNDC_PLAYER_GLOBAL,SNVT_TIME,0.0)
    RegisterNetworkedVariable("juggEmergencyShieldEnd",SNDC_PLAYER_GLOBAL,SNVT_TIME,0.0)
    RegisterNetworkedVariable("juggEmergencyShieldReady",SNDC_PLAYER_EXCLUSIVE,SNVT_BOOL,false)
    RegisterNetworkedVariable("juggDuelEnd",SNDC_GLOBAL,SNVT_TIME,0.0)
    Remote_RegisterFunction("JuggHackBegin")
    Remote_RegisterFunction("JuggHackProgress")
    Remote_RegisterFunction("JuggHackEnd")
    Remote_RegisterFunction("JuggChanceUpdate")
    RegisterNetworkedVariable("juggOutlineAt",SNDC_GLOBAL,SNVT_TIME,0.0)
    RegisterNetworkedVariable("juggSpecial",SNDC_GLOBAL,SNVT_INT,0)
    Remote_RegisterFunction("JuggFinaleWarning")
    Remote_RegisterFunction("JuggBatteryHealFeedback")
    Remote_RegisterFunction("JuggBatteryEvent")
    Remote_RegisterFunction("JuggTitanHUDMetadata")
    Remote_RegisterFunction("JuggPowerHealthUpdate")
    RegisterNetworkedVariable( "juggPhase", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "juggRound", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "juggRounds", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "juggRoundEnd", SNDC_GLOBAL, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable( "juggIsBoss", SNDC_PLAYER_EXCLUSIVE, SNVT_BOOL, false )
    RegisterNetworkedVariable( "juggSmokeReadyAt", SNDC_PLAYER_EXCLUSIVE, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable( "juggRespawnAt", SNDC_PLAYER_EXCLUSIVE, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable( "juggOutOfBoundsAt", SNDC_PLAYER_EXCLUSIVE, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable("juggHull",SNDC_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("juggHullHigh",SNDC_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("juggHullMax",SNDC_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("juggHullMaxHigh",SNDC_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("juggShield",SNDC_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("juggShieldHigh",SNDC_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("juggPower1",SNDC_GLOBAL,SNVT_INT,-1)
    RegisterNetworkedVariable("juggPower2",SNDC_GLOBAL,SNVT_INT,-1)
    RegisterNetworkedVariable("juggBoost",SNDC_PLAYER_EXCLUSIVE,SNVT_INT,0)
    RegisterNetworkedVariable("juggOverchargeEnd",SNDC_PLAYER_EXCLUSIVE,SNVT_TIME,0.0)
    RegisterNetworkedVariable( "juggBatteryExpiresAt", SNDC_PLAYER_EXCLUSIVE, SNVT_TIME, 0.0 )
    RegisterNetworkedVariable( "juggAegisTier", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "juggAegisKills", SNDC_GLOBAL, SNVT_INT, 0 )
    RegisterNetworkedVariable( "juggAegisPerTier", SNDC_GLOBAL, SNVT_INT, 3 )
    Remote_RegisterFunction( "JuggDamageFlyout" )
}

var function Jugg_OnSmokeAttack( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    if ( GAMETYPE != GAMEMODE_JUGG )
        return OnWeaponPrimaryAttack_titanability_smoke( weapon, attackParams )
    entity owner = weapon.GetWeaponOwner()
    if ( !IsValid( owner ) || !owner.IsPlayer() || !owner.GetPlayerNetBool( "juggIsBoss" ) )
        return OnWeaponPrimaryAttack_titanability_smoke( weapon, attackParams )
    if ( !IsAlive( owner ) || !owner.IsTitan() || GetGlobalNetInt( "juggPhase" ) != 2 )
        return 0
    if(owner.GetPlayerNetBool("juggEmergencyShieldReady"))
    {
        #if SERVER
            JuggActivateEmergencyShield(owner)
        #endif
        return 0
    }
    if(Time()<owner.GetPlayerNetTime("juggSmokeReadyAt")) return 0
    return OnWeaponPrimaryAttack_titanability_smoke( weapon, attackParams )
}

int function JuggGetHealthNet(string key)
{
    return GetGlobalNetInt(key)+512*GetGlobalNetInt(key+"High")
}

var function Jugg_OnUpgradeCoreAttack(entity weapon,WeaponPrimaryAttackParams attackParams)
{
    if(GAMETYPE!=GAMEMODE_JUGG) return OnWeaponPrimaryAttack_UpgradeCore(weapon,attackParams)
    entity owner=weapon.GetWeaponOwner()
    if(!IsValid(owner) || !IsAlive(owner) || !owner.IsTitan()) return 0
    entity soul=owner.GetTitanSoul()
    if(!IsValid(soul) || TitanCoreInUse(owner) || !CheckCoreAvailable(weapon)) return 0
    if(weapon in juggCore.upgradeReadyAt && Time()<juggCore.upgradeReadyAt[weapon]) return 0
    array<entity> stale
    foreach(entity old,float deadline in juggCore.upgradeReadyAt) if(!IsValid(old)) stale.append(old)
    foreach(entity old in stale) delete juggCore.upgradeReadyAt[old]

    juggCore.upgradeReadyAt[weapon] <- Time()+max(1.0,weapon.GetCoreDuration()+0.5)
    #if SERVER
        print("[Jugg] Upgrade Core begin tier "+soul.GetTitanSoulNetInt("upgradeCount"))
    #endif
    var result=OnWeaponPrimaryAttack_UpgradeCore(weapon,attackParams)
    #if SERVER
        print("[Jugg] Upgrade Core applied tier "+soul.GetTitanSoulNetInt("upgradeCount"))
    #endif
    return result
}
