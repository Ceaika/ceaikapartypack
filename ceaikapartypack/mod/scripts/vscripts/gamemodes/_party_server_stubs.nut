global function BodySwap_Init
global function Echo_DecoyStarted
global function Echo_Init
global function Echo_TryScreech
global function GTFO_Init
global function GamemodeJugg_Init
global function GruntCallouts_Context
global function GruntCallouts_Ordnance
global function GruntEvent_ApplyStim
global function GruntEvent_HeatShieldCaught
global function GruntEvent_HeatShieldPileFX
global function GruntEvent_HeatShieldUp
global function GruntEvent_StimCandidates
global function GruntEvent_StimTargeted
global function HotPotato_Init
global function JuggActivateBoost
global function JuggRatePilotSpawns
global function PH_Init
global function PH_RecordShot
global function PartyFeed
global function PartyLobby_Init

void function BodySwap_Init() {}
void function Echo_DecoyStarted( entity projectile ) {}
void function Echo_Init() {}
bool function Echo_TryScreech( entity p ) { return false }
void function GTFO_Init() {}
void function GamemodeJugg_Init() {}
bool function GruntCallouts_Context( entity p ) { return false }
void function GruntCallouts_Ordnance( entity p,entity weapon ) {}
bool function GruntEvent_ApplyStim( entity thrower,entity target ) { return false }
bool function GruntEvent_HeatShieldCaught( entity vortexWeapon,entity attacker,vector origin,string weaponName="" ) { return false }
void function GruntEvent_HeatShieldPileFX( entity vortexWeapon,var fxRefs ) {}
void function GruntEvent_HeatShieldUp( entity vortexWeapon ) {}
array<entity> function GruntEvent_StimCandidates() { return [] }
bool function GruntEvent_StimTargeted( entity thrower ) { return false }
void function HotPotato_Init() {}
bool function JuggActivateBoost( entity player ) { return false }
void function JuggRatePilotSpawns( int checkClass,array<entity> spawnpoints,int team,entity player ) {}
void function PH_Init() {}
void function PH_RecordShot( entity weapon,vector start,vector direction ) {}
void function PartyFeed( entity player, string text, vector color = <90,210,255> ) {}
void function PartyLobby_Init() {}
