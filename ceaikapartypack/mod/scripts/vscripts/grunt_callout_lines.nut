global function GruntCallouts_Lines
array<string> function GruntCallouts_Lines(string family)
{
    switch(family)
    {
        case "enemy_titan": return ["diag_imc_grunt1_bc_enemytitanspotcall_01","diag_imc_grunt1_bc_enemytitanspotcall_02","diag_imc_grunt1_bc_spotclosetitancall_01"]
        case "titan_behind": return ["diag_imc_grunt1_bc_fleePlayerTitanCall_01","diag_imc_grunt1_bc_fleePlayerTitanCall_02","diag_imc_grunt1_bc_fleePlayerTitanCall_03","diag_imc_grunt1_bc_fleePlayerTitanCall_04","diag_imc_grunt1_bc_fleePlayerTitanCall_05","diag_imc_grunt1_bc_fleePlayerTitanCall_06","diag_imc_grunt1_bc_fleePlayerTitanCall_07"]
        case "friendly_titan": return ["diag_imc_grunt1_bc_reactTitanfallFriendlyArrives_01","diag_imc_grunt1_bc_titancheer_01","diag_sp_ReaperTown_BM103_01a_01_mcor_grunt2","diag_sp_corkscrew_SE131_19_01_mcor_grunt1"]
        case "grenade": return [
            "diag_imc_grunt1_bc_grenadeOutCall_01",
            "diag_imc_grunt1_bc_grenadeOutCall_02",
            "diag_imc_grunt1_bc_grenadeOutCall_02a",
            "diag_imc_grunt1_bc_grenadeOutCall_03",
            "diag_imc_grunt1_bc_grenadeOutCall_04",
            "diag_imc_grunt1_bc_grenadeOutCall_05",
            "diag_imc_grunt1_bc_grenadeOutCall_06",
            "diag_imc_grunt1_bc_grenadeOutCall_07",
            "diag_imc_grunt1_bc_grenadeOutCall_08",
            "diag_imc_grunt1_bc_grenadeOutCall_09"
        ]
        case "firestar": return [
            "diag_imc_grunt1_bc_usingGrenadeThermite_01",
            "diag_imc_grunt1_bc_usingGrenadeThermite_02",
            "diag_imc_grunt1_bc_usingGrenadeThermite_03"
        ]
        case "smoke": return [
            "diag_imc_grunt1_bc_usingGrenadeElecSmoke_01",
            "diag_imc_grunt1_bc_usingGrenadeElecSmoke_01a",
            "diag_imc_grunt1_bc_usingGrenadeElecSmoke_02",
            "diag_imc_grunt1_bc_usingGrenadeElecSmoke_03"
        ]
        case "at": return [
            "diag_imc_grunt1_bc_switchingToAT_01",
            "diag_imc_grunt1_bc_switchingToAT_02"
        ]
        case "ally": return [
            "diag_imc_grunt1_bc_allygruntdown_01",
            "diag_imc_grunt1_bc_allygruntdown_01a",
            "diag_imc_grunt1_bc_allygruntdown_02",
            "diag_imc_grunt1_bc_allygruntdown_02a",
            "diag_imc_grunt1_bc_allygruntdown_03",
            "diag_imc_grunt1_bc_allygruntdown_03a",
            "diag_imc_grunt1_bc_allygruntdown_04",
            "diag_imc_grunt1_bc_allygruntdown_05"
        ]
    }
    return []
}
