global function GruntEvent_ClientInit
void function GruntEvent_ClientInit() { thread GruntEvent_LoadoutMode(); }
void function GruntEvent_LoadoutMode()
{
    wait 1.0
    OnThreadEnd(function() { RunUIScript("PartyLoadout_SetMode",0); })
    while(true)
    {
        int mode=GAMETYPE=="jugg" ? (GetGlobalNetInt("juggSpecial")==10 ? 2 : 1) : 0
        RunUIScript("PartyLoadout_SetMode",mode)
        wait 0.2
    }
}
