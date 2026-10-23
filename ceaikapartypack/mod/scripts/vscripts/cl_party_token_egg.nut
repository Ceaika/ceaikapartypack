untyped
global function PartyTokenEgg_Init
global function PartyTokenEgg_Show

struct {
    bool showing = false
    float nextAllowed = 0.0
} tokenEgg

void function PartyTokenEgg_Init()
{
    AddCallback_OnReceivedSayTextMessage(PartyTokenEgg_Chat)
}

ClClient_MessageStruct function PartyTokenEgg_Chat(ClClient_MessageStruct msg)
{
    // only the sender sees it. dont break chat or the supporter formatting
    if(!IsValid(msg.player) || msg.player != GetLocalClientPlayer()) return msg
    if(msg.message.tolower().find("token stealer") != null)
        PartyTokenEgg_Show()
    return msg
}

void function PartyTokenEgg_Show()
{
    if(tokenEgg.showing || Time() < tokenEgg.nextAllowed) return
    tokenEgg.showing = true
    tokenEgg.nextAllowed = Time() + 5.0
    thread PartyTokenEgg_Animate()
}

void function PartyTokenEgg_Animate()
{
    table visual = { topo = null, rui = null }
    OnThreadEnd(void function() : (visual)
    {
        if(visual.rui != null) RuiDestroyIfAlive(visual.rui)
        if(visual.topo != null) RuiTopology_Destroy(visual.topo)
        tokenEgg.showing = false
    })
    try
    {
        visual.topo = RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
        visual.rui = RuiCreate($"ui/basic_image.rpak",visual.topo,RUI_DRAW_HUD,400)
        RuiSetImage(visual.rui,"basicImage",$"rui/ceaika/token_egg")
        RuiSetFloat3(visual.rui,"basicImageColor",<1,1,1>)
        RuiSetFloat(visual.rui,"basicImageAlpha",1.0)
    }
    catch(error) { return }
    float started = Time()
    // 0.35s up, 1s still, 0.35s down
    while(Time() - started < 1.7)
    {
        float elapsed = Time() - started
        float amount = elapsed < 0.35 ? clamp(elapsed/0.35,0.0,1.0) :
            (elapsed < 1.35 ? 1.0 : clamp((1.7-elapsed)/0.35,0.0,1.0))
        amount = amount*amount*(3.0-2.0*amount)
        float sw = GetScreenSize()[0]
        float sh = GetScreenSize()[1]
        float y = sh*(1.0-amount)
        RuiTopology_UpdatePos(visual.topo,<0,y,0>,<sw,0,0>,<0,sh,0>)
        WaitFrame()
    }
}
