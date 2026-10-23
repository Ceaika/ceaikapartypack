untyped
global function PartyAdminEvents_ClientInit

struct
{
    int generation = 0
    int textGeneration = 0
    bool scare = false
} adminClient

void function PartyAdminEvents_ClientInit()
{
    AddServerToClientStringCommandCallback("party_admin",PartyAdminEvents_Command)
}

void function PartyAdminEvents_Command(array<string> args)
{
    if (args.len()==0) return
    if (args[0]=="stop")
    {
        adminClient.generation++
        adminClient.textGeneration++
        if (GAMETYPE=="echo") Echo_AdminNoticeClear()
        return
    }
    if (args[0]=="say" && args.len()==2)
        thread PartyAdminEvents_Text(PartyUI_Decode(args[1]),++adminClient.textGeneration)
    if (args[0]=="jumpscare" && GAMETYPE=="echo" && !adminClient.scare)
        thread PartyAdminEvents_Scare(adminClient.generation)
}

// rough letter widths for the stock rui font so narrow letters dont count as a full width
float function PartyAdminEvents_Advance(string glyph)
{
    if (glyph==" ") return 0.28
    if (glyph.len()>1) return 1.05
    if ("ilI.,!:;'|".find(glyph)!=null) return 0.28
    if ("frt()[]".find(glyph)!=null) return 0.40
    if ("mwMW@%".find(glyph)!=null) return 0.94
    if (glyph[0]>=65 && glyph[0]<=90) return 0.70
    return 0.57
}

string function PartyAdminEvents_WrapText(string message,float width)
{
    string result = ""
    int start = 0
    while (start<message.len())
    {
        int end = start
        int space = -1
        float used = 0.0
        while (end<message.len())
        {
            int next = end+1
            while (next<message.len() && (message[next]&192)==128) next++
            float advance = PartyAdminEvents_Advance(message.slice(end,next))
            if (used+advance>width && end>start) break
            if (message[end]==32) space = end
            end = next
            used += advance
        }
        if (end<message.len() && message[end]!=32 && space>start) end = space
        if (result!="") result += "\n"
        result += message.slice(start,end)
        start = end
        while (start<message.len() && message[start]==32) start++
    }
    return result
}

int function PartyAdminEvents_TextEnd(string message,int letters)
{
    int end = 0
    int count = 0
    while (end<message.len() && count<letters)
    {
        if (message[end]!=10) count++
        end++
        while (end<message.len() && (message[end]&192)==128) end++
    }
    return end
}

void function PartyAdminEvents_Text(string message,int generation)
{
    array<var> rows
    OnThreadEnd(function() : (rows) {
        foreach (var row in rows) RuiDestroyIfAlive(row)
    })
    int letters = 0
    for (int i=0;i<message.len();i++)
        if ((message[i]&192)!=128) letters++
    float start = Time()
    float typing = letters*0.08
    while (generation==adminClient.textGeneration && Time()-start<typing+5.0)
    {
        float[2] screen = GetScreenSize()
        // fullscreen rui fonts are in 1080p units. 8% margins
        float available = screen[0]*1080.0/max(1.0,screen[1])*0.84
        float fontSize = 110.0
        string wrapped = PartyAdminEvents_WrapText(message,available/fontSize)
        int lines = split(wrapped,"\n").len()
        while (lines>12 || lines*fontSize*1.25>864.0)
        {
            fontSize *= 0.85
            wrapped = PartyAdminEvents_WrapText(message,available/fontSize)
            lines = split(wrapped,"\n").len()
        }
        float age = Time()-start
        int count = PartyAdminEvents_TextEnd(wrapped,int(age/0.08)+1)
        array<string> visible = split(wrapped.slice(0,count),"\n")
        while (rows.len()<lines)
        {
            var row = CreateFullscreenRui($"ui/cockpit_console_text_center.rpak",1100)
            rows.append(row)
            RuiSetInt(row,"maxLines",1)
            RuiSetInt(row,"lineNum",0)
            RuiSetFloat(row,"thicken",0.0)
            RuiSetFloat3(row,"msgColor",<1,1,1>)
        }
        foreach (int i,var row in rows)
        {
            // centre each line on its own, multiline alignment is broken
            float y = (float(i)-float(lines-1)*0.5)*fontSize*1.15/1080.0
            RuiSetFloat(row,"msgFontSize",fontSize)
            RuiSetFloat2(row,"msgPos",<0,y,0>)
            RuiSetString(row,"msgText",i<visible.len() ? visible[i] : "")
            RuiSetFloat(row,"msgAlpha",i<visible.len() ? clamp((typing+5.0-age)/0.4,0.0,1.0) : 0.0)
        }
        WaitFrame()
    }
}

void function PartyAdminEvents_Scare(int generation)
{
    entity player = GetLocalClientPlayer()
    if (!IsValid(player) || !IsAlive(player) || GetLocalViewPlayer()!=player) return
    vector forward = AnglesToForward(player.EyeAngles())
    vector origin = player.EyePosition()+forward*180-<0,0,40>
    entity model = CreateClientSidePropDynamic(origin,VectorToAngles(-forward),ECHO_PROWLER)
    if (!IsValid(model)) return
    adminClient.scare = true
    OnThreadEnd(function() : (model) {
        if (IsValid(model)) model.Destroy()
        adminClient.scare = false
    })
    model.Anim_Play("pr_claw_attack")
    Echo_AdminNotice()
    float start = Time()
    while (generation==adminClient.generation && Time()-start<0.85 && IsValid(player) && IsAlive(player))
    {
        // locked to the view, its just a visual
        forward = AnglesToForward(player.EyeAngles())
        float distance = GraphCapped(Time()-start,0.0,0.65,180.0,38.0)
        model.SetOrigin(player.EyePosition()+forward*distance-<0,0,40>)
        vector angles = VectorToAngles(-forward)
        model.SetAngles(<0,angles.y,0>)
        WaitFrame()
    }
}
