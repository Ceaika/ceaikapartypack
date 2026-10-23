untyped
global function GruntEvent_ChatterAttack
global function GruntEvent_MedkitCollision
#if SERVER
#endif
// Approved voice lines; original review IDs: 1,2,3,7,8,10,12,14,15
const array<string> GRUNT_EVENT_LINES = [
    "diag_sp_intro_WD104_24_01_mcor_grunt1",
    "diag_sp_intro_WD103_02_01_mcor_grunt2",
    "diag_sp_intro_WD104_26_01_mcor_grunt3",
    "diag_sp_intro_WD101_04_01_mcor_grunt3",
    "diag_sp_intro_WD101_05_01_mcor_grunt2",
    "diag_sp_intro_WD101_07_01_mcor_grunt4",
    "diag_sp_intro_WD103_03_01_mcor_grunt3",
    "diag_sp_intro_WD104_25_01_mcor_grunt2",
    "diag_sp_intro_WD104_27_01_mcor_grunt4"
]
var function GruntEvent_ChatterAttack(entity weapon,WeaponPrimaryAttackParams attackParams)
{
    entity p=weapon.GetWeaponOwner()
    if(!IsValid(p) || !IsAlive(p) || !p.IsPlayer() || p.IsTitan()) return 0
    #if SERVER
        if(GruntCallouts_Context(p)) return 100
        // Approved general chatter remains the fallback.
        // 50% corner-us; the other approved lines share the remaining 50%.
        array<int> approved=[1,2,3,4,5,6,7,8]
        int index=RandomInt(100)<50 ? 0 : approved[RandomInt(approved.len())]
        string line=GRUNT_EVENT_LINES[index]
        EmitSoundOnEntity(p,line)
        print("[GruntEvent] chatter "+line)
    #endif
    return 100
}

// Support grunt Stim Blade (ordnance). The throw itself locks onto a hurt
// teammate near the aim (grunt_event.nut); if it did not, where the blade first
// lands it stims teammates under half health within reach. Then it disappears.
const float GRUNT_MEDKIT_RADIUS = 150.0
void function GruntEvent_MedkitCollision(entity projectile,vector pos,vector normal,entity hitEnt,int hitbox,bool critical)
{
    #if SERVER
        if(!IsValid(projectile) || "gruntMedkitUsed" in projectile.s) return
        projectile.s.gruntMedkitUsed <- true
        entity thrower=projectile.GetOwner()
        int healed=0
        if(!GruntEvent_StimTargeted(thrower))
        {
            foreach(entity p in GruntEvent_StimCandidates())
            {
                if(!IsAlive(p) || p.GetTeam()!=projectile.GetTeam()) continue
                if(Distance(p.GetOrigin(),pos)>GRUNT_MEDKIT_RADIUS && Distance(p.EyePosition(),pos)>GRUNT_MEDKIT_RADIUS) continue
                if(GruntEvent_ApplyStim(thrower,p)) healed++
            }
            if(healed==0 && IsValid(thrower) && thrower.IsPlayer()) PartyFeed(thrower,"STIM BLADE | Nobody there needs healing",<255,190,70>)
        }
        print("[GruntEvent] stim blade landed, healed "+healed)
        projectile.Destroy()
    #endif
}

#if SERVER
#endif
