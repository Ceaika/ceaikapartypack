global function BodySwap_Init
global function GamemodeJugg_Init
global function HotPotato_Init
global function JuggActivateBoost
global function JuggActivateEmergencyShield
global function JuggRatePilotSpawns
global function PH_Init
global function PH_RecordShot
global function PartyLobby_Init

void function BodySwap_Init() {}
void function GamemodeJugg_Init() {}
void function HotPotato_Init() {}
bool function JuggActivateBoost( entity player ) { return false }
void function JuggActivateEmergencyShield( entity player ) {}
void function JuggRatePilotSpawns( int checkClass,array<entity> spawnpoints,int team,entity player ) {}
void function PH_Init() {}
void function PH_RecordShot( entity weapon,vector start,vector direction ) {}
void function PartyLobby_Init() {}
