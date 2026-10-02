global function PH_HunterPrimaryAttack
var function PH_HunterPrimaryAttack(entity weapon, WeaponPrimaryAttackParams attackParams)
{
    #if SERVER && MP
        if (GAMETYPE == "prophunt") PH_RecordShot(weapon,attackParams.pos,attackParams.dir)
    #endif
    ShotgunBlast(weapon,attackParams.pos,attackParams.dir,8,weapon.GetWeaponDamageFlags())

    return weapon.GetAmmoPerShot()
}
