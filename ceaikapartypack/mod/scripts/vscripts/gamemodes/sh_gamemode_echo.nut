global function Echo_DecoyCollision
global function Echo_DecoyIgnite
global function Sh_Echo_Init
global function Echo_CanExecute
global function Echo_Maps
global function Echo_BoundaryModels
global const string GAMEMODE_ECHO = "echo"
global const asset ECHO_PROWLER = $"models/creatures/prowler/hush_prowler.mdl"

void function Sh_Echo_Init()
{
    Party_SetWeaponHandler("echoscreech",Echo_ScreechAttack)
    Party_SetEchoDecoyHandlers(Echo_DecoyCollision,Echo_DecoyIgnite)
    AddCallback_OnCustomGamemodesInit(Echo_Create)
    AddCallback_OnRegisteringCustomNetworkVars(Echo_Network)
}
void function Echo_Create()
{
    GameMode_Create(GAMEMODE_ECHO)
    GameMode_SetName(GAMEMODE_ECHO,"#GAMEMODE_ECHO")
    GameMode_SetDesc(GAMEMODE_ECHO,"#PL_echo_desc")
    GameMode_SetGameModeAnnouncement(GAMEMODE_ECHO,"tdm_modeDesc")
    GameMode_SetDefaultTimeLimits(GAMEMODE_ECHO,9999,0.0)
    GameMode_SetDefaultScoreLimits(GAMEMODE_ECHO,5,0)
    GameMode_AddScoreboardColumnData(GAMEMODE_ECHO,"#PH_SCOREBOARD_ELIMS",PGS_KILLS,2)
    GameMode_SetColor(GAMEMODE_ECHO,[255,145,30,255])
    AddPrivateMatchMode(GAMEMODE_ECHO)
    #if !UI
        GameMode_SetScoreCompareFunc(GAMEMODE_ECHO,CompareKills)
    #endif
    #if SERVER
        GameMode_AddServerInit(GAMEMODE_ECHO,Echo_Init)
        GameMode_SetPilotSpawnpointsRatingFunc(GAMEMODE_ECHO,RateSpawnpoints_Generic)
        GameMode_SetTitanSpawnpointsRatingFunc(GAMEMODE_ECHO,RateSpawnpoints_Generic)
    #elseif CLIENT
        GameMode_AddClientInit(GAMEMODE_ECHO,Cl_Echo_Init)
    #endif
}
array<string> function Echo_Maps() { return ["mp_lf_stacks","mp_lf_uma","mp_lf_meadow"]; }
bool function Echo_CanExecute(entity attacker,entity target) { return false; }
// Baked radius steps: client-side modelscale does not resize the rendered mesh.
array<asset> function Echo_BoundaryModels()
{
    return [
        $"models/echo/void_00.mdl",
        $"models/echo/void_01.mdl",
        $"models/echo/void_02.mdl",
        $"models/echo/void_03.mdl",
        $"models/echo/void_04.mdl",
        $"models/echo/void_05.mdl",
        $"models/echo/void_06.mdl",
        $"models/echo/void_07.mdl",
        $"models/echo/void_08.mdl",
        $"models/echo/void_09.mdl",
        $"models/echo/void_10.mdl",
        $"models/echo/void_11.mdl",
        $"models/echo/void_12.mdl",
        $"models/echo/void_13.mdl",
        $"models/echo/void_14.mdl",
        $"models/echo/void_15.mdl",
        $"models/echo/void_16.mdl",
        $"models/echo/void_17.mdl",
        $"models/echo/void_18.mdl",
        $"models/echo/void_19.mdl",
        $"models/echo/void_20.mdl",
        $"models/echo/void_21.mdl",
        $"models/echo/void_22.mdl",
        $"models/echo/void_23.mdl",
        $"models/echo/void_24.mdl",
        $"models/echo/void_25.mdl",
        $"models/echo/void_26.mdl",
        $"models/echo/void_27.mdl",
        $"models/echo/void_28.mdl",
        $"models/echo/void_29.mdl",
        $"models/echo/void_30.mdl",
        $"models/echo/void_31.mdl",
        $"models/echo/void_32.mdl",
        $"models/echo/void_33.mdl",
        $"models/echo/void_34.mdl",
        $"models/echo/void_35.mdl",
        $"models/echo/void_36.mdl",
        $"models/echo/void_37.mdl",
        $"models/echo/void_38.mdl",
        $"models/echo/void_39.mdl",
        $"models/echo/void_40.mdl",
        $"models/echo/void_41.mdl",
        $"models/echo/void_42.mdl",
        $"models/echo/void_43.mdl",
        $"models/echo/void_44.mdl",
        $"models/echo/void_45.mdl",
        $"models/echo/void_46.mdl",
        $"models/echo/void_47.mdl",
        $"models/echo/void_48.mdl",
        $"models/echo/void_49.mdl",
        $"models/echo/void_50.mdl",
        $"models/echo/void_51.mdl",
        $"models/echo/void_52.mdl",
        $"models/echo/void_53.mdl",
        $"models/echo/void_54.mdl",
        $"models/echo/void_55.mdl",
        $"models/echo/void_56.mdl",
        $"models/echo/void_57.mdl",
        $"models/echo/void_58.mdl",
        $"models/echo/void_59.mdl",
        $"models/echo/void_60.mdl",
        $"models/echo/void_61.mdl",
        $"models/echo/void_62.mdl",
        $"models/echo/void_63.mdl",
        $"models/echo/void_far.mdl"
    ]
}
void function Echo_Network()
{
    if(GAMETYPE!=GAMEMODE_ECHO) return
    Remote_RegisterFunction("Echo_ScreechFX")
    Remote_RegisterFunction("Echo_HiderVocalFX")
    Remote_RegisterFunction("Echo_GruntNotice")
    Remote_RegisterFunction("Echo_DecoyFX")
    Remote_RegisterFunction("Echo_DecoyMotion")
    RegisterNetworkedVariable("echoPhase",SNDC_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("echoRound",SNDC_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("echoAlive",SNDC_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("echoEnd",SNDC_GLOBAL,SNVT_TIME,0.0)
    RegisterNetworkedVariable("echoHunter",SNDC_PLAYER_GLOBAL,SNVT_BOOL,false)
    RegisterNetworkedVariable("echoActive",SNDC_PLAYER_GLOBAL,SNVT_BOOL,false)
    RegisterNetworkedVariable("echoQuiet",SNDC_PLAYER_GLOBAL,SNVT_BOOL,false)
    RegisterNetworkedVariable("echoShovedUntil",SNDC_PLAYER_GLOBAL,SNVT_TIME,0.0)
    RegisterNetworkedVariable("echoLastScreech",SNDC_PLAYER_GLOBAL,SNVT_TIME,0.0)
    RegisterNetworkedVariable("echoScreechReady",SNDC_PLAYER_EXCLUSIVE,SNVT_TIME,0.0)
}

void function Echo_DecoyCollision(entity projectile,vector pos,vector normal,entity hitEnt,int hitbox,bool isCritical)
{
    if(projectile.GrenadeHasIgnited()) return
    if(IsHumanSized(hitEnt)) return
    if(PlantStickyGrenade(projectile,pos,normal,hitEnt,hitbox,4.0,false)) projectile.GrenadeIgnite()
}
void function Echo_DecoyIgnite(entity projectile)
{
    projectile.SetDoesExplode(false)
    #if SERVER
        Echo_DecoyStarted(projectile)
    #endif
}

var function Echo_ScreechAttack(entity weapon,WeaponPrimaryAttackParams attackParams)
{
    if(GAMETYPE!=GAMEMODE_ECHO) return 0
    entity p=weapon.GetWeaponOwner()
    if(!IsValid(p) || !p.IsPlayer() || !IsAlive(p) || !p.GetPlayerNetBool("echoActive") || !p.GetPlayerNetBool("echoHunter") || GetGlobalNetInt("echoPhase")!=2 || Time()<p.GetPlayerNetTime("echoScreechReady")) return 0
    #if SERVER
        if(!Echo_TryScreech(p)) return 0
    #endif
    return 100
}
