global function Party_SetEchoDecoyHandlers
global function Party_EchoDecoyCollision
global function Party_EchoDecoyIgnite
global function Party_SetWeaponHandler
global function Party_WeaponHandlerCount
global function Party_EchoScreechAttack
global function Party_TacticalAttack
global function Party_SmokeAttack
global function Party_UpgradeCoreAttack

// Weapon callbacks named by the pack's keyvalues overrides (pilot tacticals,
// electric smoke, Upgrade Core). The game looks these up whenever it loads the
// weapon, which can happen where the party modes' scripts are not loaded at
// all: the main menu (some other mods load weapons there), the campaign. A
// missing callback is a crash ("Couldn't find callback function").
//
// So this file loads everywhere and names nothing else (an unknown name would
// not compile there). The multiplayer scripts hand it their handlers when they
// load (Party_SetWeaponHandler): Hot Potato's tacticals and Juggernaut's smoke
// and Upgrade Core, each of which runs the stock behaviour outside its mode.

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

// Always-loaded callback names remain valid in menus/campaign weapon precaches.
// Hush supplies the actual MP handlers when its shared script loads.

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
