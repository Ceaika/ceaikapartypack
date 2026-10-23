global function Party_SetEchoDecoyHandlers
global function Party_EchoDecoyCollision
global function Party_EchoDecoyIgnite
global function Party_SetWeaponHandler
global function Party_WeaponHandlerCount
global function Party_EchoScreechAttack
global function Party_TacticalAttack
global function Party_SmokeAttack
global function Party_UpgradeCoreAttack

// weapon callbacks the keyvalues point at. the game looks these up whenever it loads the weapon,
// even in the main menu or campaign where our scripts dont exist. missing callback = crash.
// so this file loads everywhere and the mp scripts hand it their handlers when they load.
// this crashed the main menu for people for a whole version before i figured it out

struct
{
    var functionref( entity, WeaponPrimaryAttackParams ) echoScreech = null
    var functionref( entity, WeaponPrimaryAttackParams ) tactical = null
    var functionref( entity, WeaponPrimaryAttackParams ) smoke = null
    var functionref( entity, WeaponPrimaryAttackParams ) upgradeCore = null
} partyWeapons

struct
{
    void functionref(entity,vector,vector,entity,int,bool) collision = null
    void functionref(entity) ignite = null
} partyEchoDecoy

void function Party_SetWeaponHandler( string kind, var functionref( entity, WeaponPrimaryAttackParams ) handler )
{
    if ( kind == "echoscreech" ) partyWeapons.echoScreech = handler
    else if ( kind == "tactical" ) partyWeapons.tactical = handler
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

// always loaded names stay valid in menus, hush gives the real handlers

void function Party_SetEchoDecoyHandlers(void functionref(entity,vector,vector,entity,int,bool) collision,void functionref(entity) ignite)
{
    partyEchoDecoy.collision=collision
    partyEchoDecoy.ignite=ignite
}
void function Party_EchoDecoyCollision(entity projectile,vector pos,vector normal,entity hitEnt,int hitbox,bool critical)
{
    if(partyEchoDecoy.collision!=null) partyEchoDecoy.collision(projectile,pos,normal,hitEnt,hitbox,critical)
}
void function Party_EchoDecoyIgnite(entity projectile)
{
    if(partyEchoDecoy.ignite!=null) partyEchoDecoy.ignite(projectile)
}

var function Party_EchoScreechAttack(entity weapon,WeaponPrimaryAttackParams attackParams)
{
    if(partyWeapons.echoScreech!=null) return partyWeapons.echoScreech(weapon,attackParams)
    return 0
}
