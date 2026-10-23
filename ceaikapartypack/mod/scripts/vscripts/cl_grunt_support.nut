global function GruntSupport_ClientInit

// shield grunts see a red cross on teammates under half hp so they know who to stim.
// its the wounded marker from the unused bleedout system lol, stuck on the chest.
// u count as a shield grunt if ur wearing the shield captain model, no networking needed
const asset GRUNT_HURT_MARKER = $"ui/bleedout_wounded_marker.rpak"
const asset GRUNT_SUPPORT_MODEL = $"models/humans/grunts/imc_grunt_shield_captain.mdl"
const float GRUNT_HURT_FRAC = 0.5

// the intro lines over the titanfall, then GRUNT MODE once u land. last one is the title
array<string> function GruntSupport_Lines() { return ["THE INTEL WAS WRONG","THEY SENT YOU TO DIE","YOU ARE DISPOSABLE","GRUNT MODE"] }
const float GRUNT_LINE_HOLD=2.4
const float GRUNT_TITLE_HOLD=3.2
// next line waits so nobody gets cut off mid read
const float GRUNT_LINE_MIN=2.6
// drop briefing that types out while u ride in
array<string> function GruntSupport_Brief()
{
    // explains why theres no pilots. mission file never decodes and reinforcements
    // stay on checking forever, armada is the punchline
    return ["~MISSION ............ |ERR: FILE CORRUPTED","TARGET ............. JUGGERNAUT TITAN","PILOT SUPPORT ...... DENIED",
        "REASON ............. PILOTS ARE VALUABLE","!REINFORCEMENTS ..... |CHECKING",
        "EXTRACTION ......... NOT PLANNED","SURVIVAL ODDS ...... 3%"]
}

// boost readouts. first entry is the header. only armada has one rn
// because it has to take back the briefing saying no reinforcements
table<string,array<string> > function GruntSupport_Readouts()
{
    return {
        armada=["// CORRECTION  -  GRUNT ARMADA","REINFORCEMENTS ..... AVAILABLE AFTER ALL","ASSET .............. %1x GRUNT","TRAINING ........... ABBREVIATED","SURVIVAL ODDS ...... STILL 3%"]
    }
}

struct {
    table<entity,var> icons
    // the line on screen: dark band, red ghost that glitches sideways, the text
    array<var> lineRuis
    var bandTopo=null
    var band=null
    int lineId=0
    float lineFreeAt=0.0
    // terminal text. 0 is the drop briefing, 1 is the boosts
    array<array<var> > termRuis
    array<int> termIds
    // eyelids for the dream thing. hard edge + soft edge, top and bottom
    array<var> lidTopos
    array<var> lids
    int grabState=0
    float grabFinish=0.0
    int dreamId=0
} file

void function GruntSupport_ClientInit()
{
    for(int i=0;i<2;i++) { file.termRuis.append([]);file.termIds.append(0); }
    thread GruntSupport_HurtIcons()
    AddServerToClientStringCommandCallback("grunt_grab_prompt",void function(array<string> args) {
        if(args.len()!=1) return
        file.grabState=args[0].tointeger()
        file.grabFinish=file.grabState==2 ? Time()+0.65 : 0.0
    })
    if(GAMETYPE=="jugg") thread GruntSupport_GrabPrompt()
    AddServerToClientStringCommandCallback("grunt_title",GruntSupport_Title)
    AddServerToClientStringCommandCallback("grunt_line",GruntSupport_Line)
    AddServerToClientStringCommandCallback("grunt_brief",GruntSupport_BriefCommand)
    AddServerToClientStringCommandCallback("grunt_readout",GruntSupport_ReadoutCommand)
    AddServerToClientStringCommandCallback("grunt_dream",GruntSupport_DreamCommand)
}

// grunt_dream sleep / wake / clear. keys are pairs of (time, how open the eyes are)
// 1 is open 0 is shut. tuned these at 5am so the numbers are whatever looked right
void function GruntSupport_DreamCommand(array<string> args)
{
    if(args.len()==0) return
    file.dreamId++
    GruntSupport_LidsClear()
    if(args[0]=="sleep" || args[0]=="sleep_hold")
    {
        DoF_LerpFarDepth(1,20,5.8)
        thread GruntSupport_Lids(file.dreamId,[0.0,1.0, 1.0,1.0, 1.35,0.0, 1.6,0.0, 2.1,0.75, 2.8,0.75, 3.3,0.0, 3.8,0.0,
            4.5,0.4, 4.9,0.4, 5.9,0.0],args[0]=="sleep_hold" ? 3600.0 : 1.2)
    }
    else if(args[0]=="wake")
    {
        DoF_SetFarDepth(1,20)
        thread GruntSupport_Lids(file.dreamId,[0.0,0.0, 0.8,0.0, 1.6,0.3, 2.0,0.3, 2.25,0.0, 2.8,0.0, 3.5,0.6, 3.9,0.6,
            4.1,0.0, 4.4,0.0, 5.2,1.0],0.0)
        thread GruntSupport_WakeFocus(file.dreamId)
    }
    else DoF_SetFarDepthToDefault()
}

// blur goes away once the eyes are open for good
void function GruntSupport_WakeFocus(int id)
{
    wait 4.4
    if(file.dreamId!=id) return
    DoF_LerpFarDepth(4000,8000,2.6)
    wait 2.8
    if(file.dreamId==id) DoF_SetFarDepthToDefault()
}

void function GruntSupport_LidsClear()
{
    foreach(var rui in file.lids) RuiDestroyIfAlive(rui)
    file.lids.clear()
    foreach(var topo in file.lidTopos) RuiTopology_Destroy(topo)
    file.lidTopos.clear()
}

// plays the eyelid keys then holds the last pose for linger seconds.
// sleep ends shut under the server blackout, then everything comes off
void function GruntSupport_Lids(int id,array<float> keys,float linger)
{
    for(int i=0;i<4;i++)
    {
        var topo=RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
        var rui=RuiCreate($"ui/basic_image.rpak",topo,RUI_DRAW_HUD,900+(i<2 ? 1 : 0))
        RuiSetFloat3(rui,"basicImageColor",<0,0,0>)
        // 0 1 = solid lids, 2 3 = soft edges
        RuiSetFloat(rui,"basicImageAlpha",i<2 ? 1.0 : 0.55)
        file.lidTopos.append(topo)
        file.lids.append(rui)
    }
    float start=Time()
    float end=keys[keys.len()-2]
    while(file.dreamId==id)
    {
        float t=Time()-start
        float open=keys[keys.len()-1]
        for(int k=0;k+2<keys.len();k+=2)
        {
            if(t<keys[k] || t>keys[k+2]) continue
            float u=keys[k+2]>keys[k] ? (t-keys[k])/(keys[k+2]-keys[k]) : 1.0
            u=u*u*(3.0-2.0*u)
            open=keys[k+1]+(keys[k+3]-keys[k+1])*u
            break
        }
        float width=GetScreenSize()[0]
        float height=GetScreenSize()[1]
        // each lid covers half the screen when shut, tiny overlap so theres no seam
        float lid=(height*0.5+4.0)*(1.0-open)
        float soft=height*0.06*(1.0-open*0.5)
        RuiTopology_UpdatePos(file.lidTopos[0],<0,0,0>,<width,0,0>,<0,max(lid,0.0),0>)
        RuiTopology_UpdatePos(file.lidTopos[1],<0,height-lid,0>,<width,0,0>,<0,max(lid,0.0),0>)
        RuiTopology_UpdatePos(file.lidTopos[2],<0,lid,0>,<width,0,0>,<0,soft,0>)
        RuiTopology_UpdatePos(file.lidTopos[3],<0,height-lid-soft,0>,<width,0,0>,<0,soft,0>)
        // soft edges fade out when ur eyes are open otherwise u get a dark band forever
        RuiSetFloat(file.lids[2],"basicImageAlpha",0.55*(1.0-open))
        RuiSetFloat(file.lids[3],"basicImageAlpha",0.55*(1.0-open))
        if(t>end+linger) break
        WaitFrame()
    }
    if(file.dreamId!=id) return
    GruntSupport_LidsClear()
    if(linger>0.0) DoF_SetFarDepthToDefault()
}

// grunt_line <n>
void function GruntSupport_Line(array<string> args)
{
    if(args.len()==0) return
    int index=args[0].tointeger()
    if(index<0 || index>=GruntSupport_Lines().len()) return
    float showAt=max(Time(),file.lineFreeAt)
    file.lineFreeAt=showAt+GRUNT_LINE_MIN
    thread GruntSupport_LineQueued(showAt,index)
}

void function GruntSupport_LineQueued(float showAt,int index)
{
    if(showAt>Time()) wait showAt-Time()
    file.lineId++
    thread GruntSupport_LineThread(file.lineId,index)
}

// radio static + beep. stopping the static early is the only way i found to make it short
void function GruntSupport_StaticHit(bool heavy)
{
    entity me=GetLocalClientPlayer()
    if(!IsValid(me)) return
    EmitSoundOnEntity(me,"HUD_Boost_Card_Radar_Jammer_Signal_Static_1P")
    EmitSoundOnEntity(me,heavy ? "UI_InGame_MarkedForDeath_PlayerMarked" : "hud_boost_card_radar_jammer_redtextbeep_1p")
    wait (heavy ? 0.45 : 0.3)
    if(IsValid(me)) StopSoundOnEntity(me,"HUD_Boost_Card_Radar_Jammer_Signal_Static_1P")
}

// grunt_brief start / end. end is when ur boots hit the ground
void function GruntSupport_BriefCommand(array<string> args)
{
    GruntSupport_TermClear(0)
    if(args.len()>0 && args[0]=="start")
        thread GruntSupport_Type(0,file.termIds[0],"// DROP BRIEFING  -  ATTRITION SQUAD 7",GruntSupport_Brief(),0.0)
}

// grunt_readout <boost> [count], %1 gets replaced with the count
void function GruntSupport_ReadoutCommand(array<string> args)
{
    if(args.len()==0) return
    table<string,array<string> > readouts=GruntSupport_Readouts()
    if(!(args[0] in readouts)) return
    array<string> text=clone readouts[args[0]]
    string count=args.len()>1 ? args[1] : ""
    for(int i=0;i<text.len();i++)
    {
        var at=text[i].find("%1")
        if(at!=null) text[i]=text[i].slice(0,expect int(at))+count+text[i].slice(expect int(at)+2)
    }
    string header=text.remove(0)
    GruntSupport_TermClear(1)
    thread GruntSupport_Type(1,file.termIds[1],header,text,4.5)
}

void function GruntSupport_TermClear(int channel)
{
    file.termIds[channel]++
    foreach(var rui in file.termRuis[channel]) RuiDestroyIfAlive(rui)
    file.termRuis[channel].clear()
}

var function GruntSupport_TermText(int channel,float size,float thicken,vector color,float x,float y)
{
    var rui=CreateFullscreenRui($"ui/cockpit_console_text_top_left.rpak",600)
    RuiSetInt(rui,"maxLines",1)
    RuiSetInt(rui,"lineNum",0)
    RuiSetFloat(rui,"thicken",thicken)
    RuiSetFloat(rui,"msgFontSize",size)
    RuiSetFloat3(rui,"msgColor",color)
    RuiSetFloat(rui,"msgAlpha",0.0)
    RuiSetFloat2(rui,"msgPos",<x,y,0>)
    file.termRuis[channel].append(rui)
    return rui
}

// lower left terminal block. header blinks on, lines type out with a cursor,
// last line is the red punchline. hold > 0 makes it stutter out after
void function GruntSupport_Type(int channel,int id,string header,array<string> lines,float hold)
{
    float x=0.06
    float y=0.6
    var top=GruntSupport_TermText(channel,22.0,0.3,<0.75,0.08,0.05>,x,y)
    RuiSetString(top,"msgText",header)
    entity me=GetLocalClientPlayer()
    if(IsValid(me)) EmitSoundOnEntity(me,"hud_boost_card_radar_jammer_redtextbeep_1p")
    for(int i=0;i<5;i++)
    {
        RuiSetFloat(top,"msgAlpha",i%2==0 ? 0.95 : 0.2)
        wait 0.06
        if(file.termIds[channel]!=id) return
    }
    RuiSetFloat(top,"msgAlpha",0.95)
    foreach(int n,string line in lines)
    {
        bool last=n==lines.len()-1
        var rui=GruntSupport_TermText(channel,20.0,0.1,last ? <0.95,0.25,0.18> : <0.88,0.86,0.8>,x,y+0.032*(n+1))
        RuiSetFloat(rui,"msgAlpha",0.9)
        // ~LABEL|ERROR decodes then fails, !LABEL|WORD blinks red forever
        string effect=line.slice(0,1)
        string value=""
        if(effect=="~" || effect=="!")
        {
            var bar=line.find("|")
            value=line.slice(expect int(bar)+1)
            line=line.slice(1,expect int(bar))
        }
        else effect=""
        for(int c=1;c<=line.len();c+=2)
        {
            RuiSetString(rui,"msgText",line.slice(0,c<line.len() ? c : line.len())+"_")
            wait 0.025
            if(file.termIds[channel]!=id) return
        }
        RuiSetString(rui,"msgText",line)
        if(effect=="~") thread GruntSupport_Decode(channel,id,rui,line,value)
        else if(effect=="!") thread GruntSupport_Checking(channel,id,rui,line,value)
        me=GetLocalClientPlayer()
        if(IsValid(me)) EmitSoundOnEntity(me,last ? "hud_boost_card_radar_jammer_redtextbeep_1p" : "UI_InGame_FD_WaveTick")
        if(!last) wait 0.3
        if(file.termIds[channel]!=id) return
    }
    if(hold<=0.0) return
    wait hold
    for(int i=0;i<6;i++)
    {
        if(file.termIds[channel]!=id) return
        foreach(var rui in file.termRuis[channel]) RuiSetFloat(rui,"msgAlpha",i%2==0 ? 0.15 : 0.7)
        wait 0.05
    }
    if(file.termIds[channel]==id) GruntSupport_TermClear(channel)
}

// fake decryption. climbs in bursts, hangs in the 80s, then fails.
// first version scrambled random letters and it looked so bad lmao
void function GruntSupport_Decode(int channel,int id,var rui,string label,string error)
{
    float percent=0.0
    float hangAt=RandomFloatRange(84.0,93.0)
    while(percent<hangAt)
    {
        if(file.termIds[channel]!=id) return
        percent=min(hangAt,percent+RandomFloatRange(3.0,11.0))
        RuiSetString(rui,"msgText",label+"DECRYPTING  "+int(percent)+"%")
        wait (RandomInt(4)==0 ? RandomFloatRange(0.2,0.35) : 0.07)
    }
    for(int i=0;i<8;i++)
    {
        if(file.termIds[channel]!=id) return
        RuiSetFloat(rui,"msgAlpha",i%2==0 ? 0.35 : 0.9)
        wait 0.1
    }
    if(file.termIds[channel]!=id) return
    RuiSetString(rui,"msgText",label+error)
    RuiSetFloat3(rui,"msgColor",<0.95,0.25,0.18>)
    thread GruntSupport_StaticHit(false)
    for(int i=0;i<5;i++)
    {
        RuiSetFloat(rui,"msgAlpha",i%2==0 ? 0.2 : 0.95)
        wait 0.07
        if(file.termIds[channel]!=id) return
    }
}

void function GruntSupport_Checking(int channel,int id,var rui,string label,string word)
{
    RuiSetFloat3(rui,"msgColor",<0.95,0.25,0.18>)
    int step=0
    while(file.termIds[channel]==id)
    {
        string dots=""
        for(int i=0;i<step%4;i++) dots+="."
        RuiSetString(rui,"msgText",label+word+dots)
        RuiSetFloat(rui,"msgAlpha",step%2==0 ? 0.95 : 0.3)
        step++
        wait 0.4
    }
}

var function GruntSupport_LineText(int sort,vector color,float thicken)
{
    var rui=CreateFullscreenRui($"ui/cockpit_console_text_center.rpak",sort)
    RuiSetInt(rui,"maxLines",1)
    RuiSetInt(rui,"lineNum",0)
    RuiSetFloat(rui,"thicken",thicken)
    RuiSetFloat3(rui,"msgColor",color)
    RuiSetFloat(rui,"msgAlpha",0.0)
    return rui
}

void function GruntSupport_LineClear()
{
    foreach(var rui in file.lineRuis) RuiDestroyIfAlive(rui)
    file.lineRuis.clear()
    if(file.band!=null) RuiDestroyIfAlive(file.band)
    file.band=null
    if(file.bandTopo!=null) RuiTopology_Destroy(file.bandTopo)
    file.bandTopo=null
}

// slams in too big, settles with a flicker, creeps bigger, glitches sometimes, stutters out.
// wayyy too many numbers in here but it looks good so dont touch it
void function GruntSupport_LineThread(int id,int index)
{
    GruntSupport_LineClear()
    bool title=index==GruntSupport_Lines().len()-1
    string text=GruntSupport_Lines()[index]
    float size=title ? 92.0 : 50.0
    float hold=title ? GRUNT_TITLE_HOLD : GRUNT_LINE_HOLD
    float width=GetScreenSize()[0]
    float height=GetScreenSize()[1]
    float s=height/1080.0
    float y=title ? 0.0 : 0.22
    file.bandTopo=RuiTopology_CreatePlane(<0,0,0>,<1,0,0>,<0,1,0>,false)
    file.band=RuiCreate($"ui/basic_image.rpak",file.bandTopo,RUI_DRAW_HUD,600)
    RuiSetFloat3(file.band,"basicImageColor",<0,0,0>)
    RuiSetFloat(file.band,"basicImageAlpha",0.0)
    var ghost=GruntSupport_LineText(601,<0.7,0.06,0.04>,0.5)
    var main=GruntSupport_LineText(602,<0.93,0.9,0.84>,title ? 0.45 : 0.3)
    file.lineRuis=[ghost,main]
    foreach(var rui in file.lineRuis) RuiSetString(rui,"msgText",text)
    thread GruntSupport_StaticHit(title)
    float start=Time()
    float tearUntil=0.0
    float nextTear=start+RandomFloatRange(0.5,0.9)
    float tearX=0.0
    while(file.lineId==id)
    {
        float t=Time()-start
        if(t>hold+0.35) break
        // in: 130% to 100% in 0.12s. out: stutter over the last 0.35s
        float slam=clamp(t/0.12,0.0,1.0)
        float scale=1.3-0.3*slam+0.05*clamp(t/hold,0.0,1.0)
        float alpha=slam
        if(t<0.3) alpha*=RandomFloatRange(0.45,1.0)
        if(t>hold) alpha=(RandomInt(3)==0 ? 0.0 : 1.0)*(1.0-(t-hold)/0.35)
        if(Time()>=nextTear)
        {
            tearUntil=Time()+RandomFloatRange(0.05,0.1)
            tearX=RandomFloatRange(-14.0,14.0)
            nextTear=Time()+RandomFloatRange(0.45,1.0)
        }
        bool tearing=Time()<tearUntil || t<0.2
        float jitter=tearing ? (t<0.2 ? RandomFloatRange(-10.0,10.0) : tearX) : RandomFloatRange(-1.0,1.0)
        float textSize=size*scale
        foreach(var rui in file.lineRuis) RuiSetFloat(rui,"msgFontSize",textSize)
        RuiSetFloat2(main,"msgPos",<(tearing ? jitter*0.35 : 0.0)*s/width,y,0>)
        RuiSetFloat(main,"msgAlpha",alpha)
        RuiSetFloat2(ghost,"msgPos",<(3.0+jitter)*s/width,y+1.5*s/height,0>)
        RuiSetFloat(ghost,"msgAlpha",alpha*(tearing ? 0.9 : 0.45))
        float bandH=textSize*1.6*s
        float bandY=height*(0.5+y)-bandH*0.62
        RuiTopology_UpdatePos(file.bandTopo,<0,bandY,0>,<width,0,0>,<0,bandH,0>)
        RuiSetFloat(file.band,"basicImageAlpha",0.55*min(alpha,slam))
        WaitFrame()
    }
    if(file.lineId==id) GruntSupport_LineClear()
}

// old expendables title card. only the jugg used it and now nobody does
// TODO: delete this, its dead code but im scared to rn
void function GruntSupport_Title(array<string> args)
{
    entity me=GetLocalViewPlayer()
    if(!IsValid(me)) return
    bool titan=args.len()>0 && args[0]=="titan"
    AnnouncementData announcement=Announcement_Create("EXPENDABLES")
    announcement.announcementStyle=ANNOUNCEMENT_STYLE_BIG
    Announcement_SetSubText(announcement,titan ? "They're sending everyone. Make it cost them." : "Bring it down. Nobody is coming for you.")
    Announcement_SetIcon(announcement,$"rui/ceaika/boost_imc")
    Announcement_SetHideOnDeath(announcement,false)
    Announcement_SetPurge(announcement,true)
    Announcement_SetDuration(announcement,4.5)
    AnnouncementFromClass(me,announcement)
}

void function GruntSupport_HurtIcons()
{
    while(true)
    {
        wait 0.2
        entity me=GetLocalClientPlayer()
        bool support=IsValid(me) && IsAlive(me) && !me.IsTitan() && GAMETYPE=="jugg" && GetGlobalNetInt("juggSpecial")==10
            && me.GetModelName()==GRUNT_SUPPORT_MODEL
        array<entity> hurt
        if(support)
        {
            foreach(entity p in GetPlayerArray())
            {
                if(p==me || !IsAlive(p) || p.IsTitan() || p.GetTeam()!=me.GetTeam()) continue
                // unknown hp reads as 0, dont mark those
                if(p.GetMaxHealth()<=0 || p.GetHealth()<=0) continue
                if(p.GetHealth()<p.GetMaxHealth()*GRUNT_HURT_FRAC) hurt.append(p)
            }
            // npc teammate the server marked as needing a stim
            entity patient=GetGlobalNetEnt("gruntPatient")
            if(IsValid(patient) && IsAlive(patient) && patient.GetTeam()==me.GetTeam()) hurt.append(patient)
        }
        foreach(entity p,var rui in clone file.icons)
        {
            if(IsValid(p) && hurt.contains(p)) continue
            RuiDestroyIfAlive(rui)
            delete file.icons[p]
        }
        foreach(entity p in hurt)
        {
            if(p in file.icons) continue
            var rui=CreateCockpitRui(GRUNT_HURT_MARKER,500)
            // chest if it has the tag, feet if not
            int chest=p.LookupAttachment("CHESTFOCUS")
            if(chest>0) RuiTrackFloat3(rui,"pos",p,RUI_TRACK_POINT_FOLLOW,chest)
            else RuiTrackFloat3(rui,"pos",p,RUI_TRACK_ABSORIGIN_FOLLOW)
            RuiSetGameTime(rui,"startTime",Time())
            RuiSetGameTime(rui,"endTime",Time()+99999.0)
            RuiSetBool(rui,"showTimer",false)
            file.icons[p] <- rui
        }
    }
}

// %use% follows ur actual keybind
void function GruntSupport_GrabPrompt()
{
    var hint=null
    OnThreadEnd(function() : (hint) { if(hint!=null) RuiDestroyIfAlive(hint); })
    while(true)
    {
        entity me=GetLocalClientPlayer()
        bool eligible=IsValid(me) && IsAlive(me) && me.IsTitan() && me.GetPlayerNetBool("juggIsBoss")
            && GetGlobalNetInt("juggSpecial")==10 && GetGlobalNetInt("juggPhase")==2
        int progress=int(clamp(1.0-(file.grabFinish-Time())/0.65,0.0,1.0)*100.0)
        bool holding=file.grabState==2
        bool visible=eligible && file.grabState>0
        if(!eligible) { file.grabState=0;file.grabFinish=0.0; }
        if(visible && hint==null)
        {
            hint=CreateFullscreenRui($"ui/cockpit_console_text_center.rpak",130)
            RuiSetInt(hint,"maxLines",1)
            RuiSetInt(hint,"lineNum",0)
            RuiSetFloat(hint,"thicken",0.15)
            RuiSetFloat(hint,"msgFontSize",25.0)
            RuiSetFloat2(hint,"msgPos",<0,0.12,0>)
        }
        if(hint!=null)
        {
            RuiSetFloat(hint,"msgAlpha",visible ? 1.0 : 0.0)
            RuiSetFloat3(hint,"msgColor",holding ? <1.0,0.55,0.2> : <1.0,1.0,1.0>)
            RuiSetString(hint,"msgText",holding ? format("HOLD %%use%%  —  GRABBING  %d%%",progress) : "Hold %use% to grab and throw")
        }
        wait 0.02
    }
}
