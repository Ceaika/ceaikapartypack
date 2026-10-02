global function Party_SetWeaponHandler
global function Party_WeaponHandlerCount
global function Party_TacticalAttack
global function Party_SmokeAttack
global function Party_UpgradeCoreAttack

struct
{
    var functionref( entity, WeaponPrimaryAttackParams ) tactical = null
    var functionref( entity, WeaponPrimaryAttackParams ) smoke = null
    var functionref( entity, WeaponPrimaryAttackParams ) upgradeCore = null
} partyWeapons

void function Party_SetWeaponHandler( string kind, var functionref( entity, WeaponPrimaryAttackParams ) handler )
{
    if ( kind == "tactical" ) partyWeapons.tactical = handler
    else if ( kind == "smoke" ) partyWeapons.smoke = handler
    else if ( kind == "upgradecore" ) partyWeapons.upgradeCore = handler
}

int function Party_WeaponHandlerCount()
{
    int count = 0
    if ( partyWeapons.tactical != null ) count++
    if ( partyWeapons.smoke != null ) count++
    if ( partyWeapons.upgradeCore != null ) count++
    return count
}

var function Party_TacticalAttack( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    if ( partyWeapons.tactical != null ) return partyWeapons.tactical( weapon, attackParams )
    return 0
}

var function Party_SmokeAttack( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    if ( partyWeapons.smoke != null ) return partyWeapons.smoke( weapon, attackParams )
    return 0
}

var function Party_UpgradeCoreAttack( entity weapon, WeaponPrimaryAttackParams attackParams )
{
    if ( partyWeapons.upgradeCore != null ) return partyWeapons.upgradeCore( weapon, attackParams )
    return 0
}
