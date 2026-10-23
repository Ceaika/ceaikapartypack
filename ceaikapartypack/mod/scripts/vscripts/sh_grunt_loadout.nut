global function GruntLoadout_Primaries
global function GruntLoadout_Pistols
global function GruntLoadout_AT
global function PartyLoadout_WeaponAllowed

array<string> function GruntLoadout_Primaries()
{
    return ["mp_weapon_rspn101","mp_weapon_rspn101_og","mp_weapon_hemlok","mp_weapon_vinson","mp_weapon_g2","mp_weapon_lmg","mp_weapon_lstar","mp_weapon_esaw"]
}
array<string> function GruntLoadout_AT()
{
    return ["mp_weapon_rocket_launcher","mp_weapon_arc_launcher","mp_weapon_mgl","mp_weapon_defender"]
}
array<string> function GruntLoadout_Pistols() { return ["mp_weapon_semipistol","mp_weapon_autopistol","mp_weapon_wingman"]; }
// mode: 0 unrestricted, 1 normal Juggernaut, 2 Expendables.
bool function PartyLoadout_WeaponAllowed(string weapon,int mode)
{
    if(mode==0) return true
    if(mode==2) return GruntLoadout_Primaries().contains(weapon) || GruntLoadout_AT().contains(weapon) || GruntLoadout_Pistols().contains(weapon)
    return ["mp_weapon_epg","mp_weapon_smr","mp_weapon_softball","mp_weapon_pulse_lmg",
        "mp_weapon_semipistol","mp_weapon_autopistol","mp_weapon_wingman",
        "mp_weapon_wingman_n","mp_weapon_shotgun_pistol",
        "mp_weapon_rocket_launcher","mp_weapon_arc_launcher","mp_weapon_mgl"].contains(weapon)
}
