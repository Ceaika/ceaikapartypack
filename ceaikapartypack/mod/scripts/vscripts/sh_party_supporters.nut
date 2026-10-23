untyped
global function PartySupporters_Init
global function PartySupporters_Start

struct {
    bool pending=false
    float validUntil=0.0
    table states
    table<string,float> linkAt
} supporters

void function PartySupporters_Init()
{
    AddCallback_OnRegisteringCustomNetworkVars(PartySupporters_Network)
}
void function PartySupporters_Network()
{
    RegisterNetworkedVariable("partySupporterRank",SNDC_PLAYER_GLOBAL,SNVT_INT,0)
    RegisterNetworkedVariable("partySupporterColour",SNDC_PLAYER_GLOBAL,SNVT_INT,0)
}
void function PartySupporters_Start()
{
    #if SERVER
        AddClientCommandCallback("party_link",PartySupporters_Link)
        thread PartySupporters_Poll()
    #elseif CLIENT
        AddCallback_OnReceivedSayTextMessage(PartySupporters_Chat)
    #endif
}

#if SERVER
bool function PartySupporters_Online()
{
    return GetConVarInt("party_supporter_sync")==1 && NSIsHttpEnabled() && GetConVarInt("ns_auth_allow_insecure")==0
}
HttpRequest function PartySupporters_Request(string path,table data)
{
    HttpRequest req
    req.method=HttpRequestMethod.POST
    req.url=GetConVarString("booking_bridge_url")+path
    req.headers["X-Booking-Token"] <- [GetConVarString("booking_bridge_token")]
    req.body=EncodeJSON(data)
    req.timeout=5
    return req
}
bool function PartySupporters_Link(entity p,array<string> args)
{
    if(!PartySupporters_Online())
    {
        Chat_ServerPrivateMessage(p,"Account linking is unavailable right now.",false,false)
        return true
    }
    string uid=p.GetUID()
    if(uid in supporters.linkAt && Time()<supporters.linkAt[uid]+60.0)
    {
        Chat_ServerPrivateMessage(p,"Wait one minute before requesting another link code.",false,false)
        return true
    }
    supporters.linkAt[uid] <- Time()
    HttpRequest req=PartySupporters_Request("/supporters/link",{uid=uid})
    bool sent=NSHttpRequest(req,void function(HttpRequestResponse response) : (p)
    {
        if(!IsValid(p)) return
        try
        {
            table data=DecodeJSON(response.body)
            if(response.statusCode==200)
                Chat_ServerPrivateMessage(p,"Private link code: "+expect string(data.code)+". Use /link-game in PartyPack Discord within 10 minutes. Do not share this code.",false,false)
            else Chat_ServerPrivateMessage(p,"Unable to create a code. Wait one minute and retry.",false,false)
        }
        catch(error) { Chat_ServerPrivateMessage(p,"Account linking is temporarily unavailable.",false,false) }
    },void function(HttpRequestFailure failure) : (p)
    {
        if(IsValid(p)) Chat_ServerPrivateMessage(p,"Account linking is temporarily unavailable.",false,false)
    })
    if(!sent) Chat_ServerPrivateMessage(p,"Account linking is temporarily unavailable.",false,false)
    return true
}
void function PartySupporters_Poll()
{
    wait 1.0
    while(true)
    {
        array<string> uids
        foreach(entity p in GetPlayerArray())
        {
            if(!IsValid(p)) continue
            string uid=p.GetUID()
            uids.append(uid)
            int rank=uid=="1007857839230" ? 2 : 0
            int colour=0
            if(Time()<supporters.validUntil && uid in supporters.states)
            {
                table data=expect table(supporters.states[uid])
                rank=uid=="1007857839230" ? 2 : int(clamp(expect int(data.rank),0,1))
                colour=int(clamp(expect int(data.preset),0,6))
            }
            p.SetPlayerNetInt("partySupporterRank",rank)
            p.SetPlayerNetInt("partySupporterColour",colour)
        }
        if(PartySupporters_Online() && !supporters.pending && uids.len()>0)
        {
            supporters.pending=true
            HttpRequest req=PartySupporters_Request("/supporters/state",{uids=uids})
            bool sent=NSHttpRequest(req,void function(HttpRequestResponse response)
            {
                supporters.pending=false
                if(response.statusCode!=200) return
                try
                {
                    supporters.states=DecodeJSON(response.body)
                    supporters.validUntil=Time()+45.0
                }
                catch(error) { print("[Supporters] Invalid sync response") }
            },void function(HttpRequestFailure failure) { supporters.pending=false })
            if(!sent) supporters.pending=false
        }
        wait 10.0
    }
}
#endif

#if CLIENT
ClClient_MessageStruct function PartySupporters_Chat(ClClient_MessageStruct msg)
{
    if(msg.shouldBlock || !IsValid(msg.player)) return msg
    int rank=msg.player.GetPlayerNetInt("partySupporterRank")
    if(rank<1) return msg
    int preset=int(clamp(msg.player.GetPlayerNetInt("partySupporterColour"),0,6))
    // northstar's rgb parser rejects 255 so everything stays under it. why. just why
    array<string> colours=["\x1b[38;2;254;138;61m","\x1b[38;2;254;209;102m","\x1b[38;2;254;100;100m","\x1b[38;2;196;161;254m","\x1b[38;2;128;230;176m","\x1b[38;2;254;155;197m"]
    string teamColour=msg.player.GetTeam()==GetLocalClientPlayer().GetTeam() ? "\x1b[111m" : "\x1b[112m"
    NSChatWriteRaw(1,"\n")
    NSChatWrite(1,teamColour)
    if(msg.isWhisper) NSChatWriteRaw(1,Localize("#HUD_CHAT_WHISPER_PREFIX"))
    if(msg.isDead) NSChatWriteRaw(1,Localize("#HUD_CHAT_DEAD_PREFIX"))
    if(msg.isTeam) NSChatWriteRaw(1,Localize("#HUD_CHAT_TEAM_PREFIX"))
    NSChatWrite(1,preset==6 ? teamColour : colours[preset])
    NSChatWriteRaw(1,(rank==2 ? "[Owner] " : "[Supporter] ")+msg.playerName)
    NSChatWrite(1,"\x1b[0m")
    NSChatWriteRaw(1,": "+msg.message)
    msg.shouldBlock=true
    return msg
}
#endif
