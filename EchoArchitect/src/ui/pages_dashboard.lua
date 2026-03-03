local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
local UI=EA.UI
local Win=UI.Window
local W=UI.Widgets
local T=UI.Theme
local DB=EA.DB

local Page=CreateFrame("Frame",nil,UIParent)
T:ApplyPanel(Page,"bg")

local function cdb()
  return EchoArchitect_CharDB
end

local function getDashDB()
  local db=cdb()
  if not db then return nil end
  db.ui=db.ui or {}
  db.ui.dashboard=db.ui.dashboard or {}
  return db.ui.dashboard
end

local function solid(parent,layer,r,g,b,a)
  local tx=parent:CreateTexture(nil,layer)
  tx:SetTexture("Interface\\Buttons\\WHITE8X8")
  tx:SetVertexColor(r,g,b,a)
  tx:SetAllPoints(parent)
  return tx
end

local function svcSelect(spellId)
  if not spellId or spellId==0 then return end
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.SelectPerk then
    pcall(ProjectEbonhold.PerkService.SelectPerk,spellId) return
  end
  if ProjectEbonhold and ProjectEbonhold.Perks and ProjectEbonhold.Perks.SelectPerk then
    pcall(ProjectEbonhold.Perks.SelectPerk,spellId) return
  end
end
local function svcReroll()
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.RequestReroll then
    pcall(ProjectEbonhold.PerkService.RequestReroll) return
  end
  if ProjectEbonhold and ProjectEbonhold.Perks and ProjectEbonhold.Perks.RequestReroll then
    pcall(ProjectEbonhold.Perks.RequestReroll) return
  end
end
local function svcBanish(idx0)
  if idx0==nil then return end
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.BanishPerk then
    pcall(ProjectEbonhold.PerkService.BanishPerk,idx0) return
  end
  if ProjectEbonhold and ProjectEbonhold.Perks and ProjectEbonhold.Perks.BanishPerk then
    pcall(ProjectEbonhold.Perks.BanishPerk,idx0) return
  end
end


local pad=12
local c=T.c

local intro=CreateFrame("Frame",nil,Page)
intro:SetPoint("TOPLEFT",Page,"TOPLEFT",pad,-pad)
intro:SetPoint("TOPRIGHT",Page,"TOPRIGHT",-pad,-pad)
intro:SetHeight(220)
T:ApplyPanel(intro,"navy")

local col1=CreateFrame("Frame",nil,intro)
col1:SetPoint("TOPLEFT",intro,"TOPLEFT",10,-10)
col1:SetPoint("BOTTOMLEFT",intro,"BOTTOMLEFT",10,10)

local col2=CreateFrame("Frame",nil,intro)
col2:SetPoint("TOPLEFT",col1,"TOPRIGHT",1,0)
col2:SetPoint("BOTTOMLEFT",col1,"BOTTOMRIGHT",1,0)

local col3=CreateFrame("Frame",nil,intro)
col3:SetPoint("TOPRIGHT",intro,"TOPRIGHT",-10,-10)
col3:SetPoint("BOTTOMRIGHT",intro,"BOTTOMRIGHT",-10,10)

local div1=CreateFrame("Frame",nil,intro)
div1:SetPoint("TOPLEFT",col1,"TOPRIGHT",0,0)
div1:SetPoint("BOTTOMLEFT",col1,"BOTTOMRIGHT",0,0)
div1:SetWidth(1)
div1:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
div1:SetBackdropColor(0,0,0,0.35)

local div2=CreateFrame("Frame",nil,intro)
div2:SetPoint("TOPLEFT",col2,"TOPRIGHT",0,0)
div2:SetPoint("BOTTOMLEFT",col2,"BOTTOMRIGHT",0,0)
div2:SetWidth(1)
div2:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
div2:SetBackdropColor(0,0,0,0.35)

local i1Title=W:Label(col1,"Introduction",14)
i1Title:SetPoint("TOP",col1,"TOP",0,0)

local i1Text=T:Font(col1,12,"")
i1Text:SetPoint("TOPLEFT",col1,"TOPLEFT",8,-24)
i1Text:SetPoint("TOPRIGHT",col1,"TOPRIGHT",-8,-24)
i1Text:SetJustifyH("LEFT")
i1Text:SetJustifyV("TOP")
i1Text:SetWordWrap(true)
i1Text:SetNonSpaceWrap(true)
i1Text:SetText("Verify all your settings and make sure everything is to your liking.\n\nEcho Library: give higher weights to Echoes you want.\n\nBlacklist makes the addon try to banish that Echo as soon as it appears.\n\nIf you never want an Echo picked, instead set its weight to a negative value.\n\nPress Start, then play normally.")

local iiiiText=T:Font(col1,12,"")
iiiiText:SetPoint("BOTTOMRIGHT",col1,"BOTTOMRIGHT",-4,-4)
iiiiText:SetPoint("BOTTOMLEFT",col1,"BOTTOMLEFT",4,-4)
iiiiText:SetJustifyH("RIGHT")
iiiiText:SetJustifyV("BOTTOM")
iiiiText:SetFont("Fonts\\ARIALN.TTF",12,"")
iiiiText:SetWordWrap(true)
iiiiText:SetNonSpaceWrap(true)
iiiiText:SetAlpha(0.65)
iiiiText:SetText("Get Boosted in Icecrown")

local i2Title=W:Label(col2,"Information",14)
i2Title:SetPoint("TOP",col2,"TOP",0,0)

local i2Text=T:Font(col2,12,"")
i2Text:SetPoint("TOPLEFT",col2,"TOPLEFT",8,-24)
i2Text:SetPoint("TOPRIGHT",col2,"TOPRIGHT",-8,-24)
i2Text:SetJustifyH("LEFT")
i2Text:SetJustifyV("TOP")
i2Text:SetWordWrap(true)
i2Text:SetNonSpaceWrap(true)
i2Text:SetText("Profiles keep your Settings and Echo weights together.\n\nMake a Profile per build, then switch anytime.\nExport/import is for sharing or backups.\n\nNeed help or found a bug?\nReach out on the Discord.")

local i3Title=W:Label(col3,"Changelog [v3.6.0]",14)
i3Title:SetPoint("TOP",col3,"TOP",0,0)

local i3Text=T:Font(col3,12,"")
i3Text:SetPoint("TOPLEFT",col3,"TOPLEFT",8,-24)
i3Text:SetPoint("TOPRIGHT",col3,"TOPRIGHT",-8,-24)
i3Text:SetJustifyH("LEFT")
i3Text:SetJustifyV("TOP")
i3Text:SetWordWrap(true)
i3Text:SetNonSpaceWrap(true)
i3Text:SetText([[
• Added Interface Options buttons
• Added Current Echoes display
• Added Manual Banish, Reroll & Select buttons to Dashboard
• Fixed rare History log inconsistency
• Fixed ESC/Interface menu opening issues
]])

local madeRow=CreateFrame("Frame",nil,col3)
madeRow:SetPoint("BOTTOMRIGHT",col3,"BOTTOMRIGHT",0,0)
madeRow:SetHeight(16)
madeRow:SetWidth(130)
madeRow:EnableMouse(true)

local madeLabel=T:Font(madeRow,12,"")
madeLabel:SetPoint("RIGHT",madeRow,"RIGHT",0,0)
madeLabel:SetJustifyH("RIGHT")
madeLabel:SetText("Made by: James")

madeRow:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
  GameTooltip:SetText("Discord: badutski2",1,0,1,1,true)
  GameTooltip:Show()
end)
madeRow:SetScript("OnLeave",function() GameTooltip:Hide() end)
local status=CreateFrame("Frame",nil,Page)
status:SetPoint("TOPLEFT",intro,"BOTTOMLEFT",0,-10)
status:SetPoint("TOPRIGHT",Page,"TOPRIGHT",-pad,-10)
status:SetHeight(32)
T:ApplyPanel(status,"navy")

local statusLeft=T:Font(status,12,"")
statusLeft:SetPoint("LEFT",status,"LEFT",10,0)
statusLeft:SetText("")

local statusRight=T:Font(status,12,"")
statusRight:SetPoint("RIGHT",status,"RIGHT",-10,0)
statusRight:SetJustifyH("RIGHT")
statusRight:SetText("")

local btnStart=W:Button(status,"Start",86,22,function()
  if EA and EA.Engine and EA.Engine.SetEnabled then
    if EA.Engine.state and EA.Engine.state.pausedReason then EA.Engine.state.pausedReason=nil end
    EA.Engine:SetEnabled(true)
  end
end)
btnStart:SetPoint("RIGHT",status,"RIGHT",-10,0)

local btnStop=W:Button(status,"Stop",86,22,function()
  if EA and EA.Engine and EA.Engine.SetEnabled then
    if EA.Engine.state and EA.Engine.state.pausedReason then EA.Engine.state.pausedReason=nil end
    EA.Engine:SetEnabled(false)
  end
end)
btnStop:SetPoint("RIGHT",btnStart,"LEFT",-8,0)

statusRight:ClearAllPoints()
statusRight:SetPoint("RIGHT",btnStop,"LEFT",-10,0)

local panels=CreateFrame("Frame",nil,Page)
panels:SetPoint("TOPLEFT",status,"BOTTOMLEFT",0,-10)
panels:SetPoint("TOPRIGHT",Page,"TOPRIGHT",-pad,-10)
panels:SetHeight(210)

local left=CreateFrame("Frame",nil,panels)
left:SetPoint("TOPLEFT",panels,"TOPLEFT",0,0)
left:SetPoint("BOTTOMLEFT",panels,"BOTTOMLEFT",0,0)
left:SetPoint("RIGHT",panels,"CENTER",-5,0)
T:ApplyPanel(left,"navy")

local right=CreateFrame("Frame",nil,panels)
right:SetPoint("TOPLEFT",left,"TOPRIGHT",10,0)
right:SetPoint("TOPRIGHT",panels,"TOPRIGHT",0,0)
right:SetPoint("BOTTOMRIGHT",panels,"BOTTOMRIGHT",0,0)
T:ApplyPanel(right,"navy")

local lTitle=W:Label(left,"Next Action",14)
lTitle:SetPoint("TOPLEFT",left,"TOPLEFT",10,-8)

local lRemain=T:Font(left,11,"")
lRemain:SetPoint("TOPRIGHT",left,"TOPRIGHT",-10,-6)
lRemain:SetJustifyH("RIGHT")
lRemain:SetText("")

local rTitle=W:Label(right,"Progress",14)
rTitle:SetPoint("TOPLEFT",right,"TOPLEFT",10,-8)

local function makeChoiceRow(parent,y)
  local row=CreateFrame("Frame",nil,parent)
  row:SetPoint("TOPLEFT",parent,"TOPLEFT",10,y)
  row:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-10,y)
  row:SetHeight(40)
  solid(row,"BACKGROUND",0.02,0.03,0.05,0.55)
  local icon=row:CreateTexture(nil,"ARTWORK")
  icon:SetSize(32,32)
  icon:SetPoint("LEFT",row,"LEFT",8,0)
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  local name=T:Font(row,12,"")
  name:SetPoint("LEFT",icon,"RIGHT",8,0)
  name:SetPoint("RIGHT",row,"RIGHT",-190,0)
  name:SetText("")
  local score=T:Font(row,12,"")
  score:SetPoint("RIGHT",row,"RIGHT",-130,0)
  score:SetJustifyH("RIGHT")
  score:SetText("")
  local btnSelect=W:Button(row,"Select",56,20)
  btnSelect:SetPoint("RIGHT",row,"RIGHT",-6,0)
  local btnBanish=W:Button(row,"Banish",56,20)
  btnBanish:SetPoint("RIGHT",btnSelect,"LEFT",-6,0)
  btnSelect:Hide()
  btnBanish:Hide()
  return {row=row,icon=icon,name=name,score=score,btnSelect=btnSelect,btnBanish=btnBanish}
end

local function setChoiceRow(r,data)
  if not r then return end
  if not data then
    r.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    r.name:SetText("")
    r.score:SetText("")
    return
  end
  if data.icon then r.icon:SetTexture(data.icon) else r.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
  local nm=tostring(data.name or "")
  local q=tonumber(data.quality or 0) or 0
  if DB and DB.QualityColor then nm=DB:QualityColor(q)..nm.."|r" end
  r.name:SetText(nm)
  local sc=data.score
  if sc==nil then r.score:SetText("")
  elseif type(sc)=="number" then r.score:SetText(string.format("%.2f",sc))
  else r.score:SetText(tostring(sc)) end
end

local row1=makeChoiceRow(left,-40)
local row2=makeChoiceRow(left,-88)
local row3=makeChoiceRow(left,-136)

local btnReroll=W:Button(left,"Reroll",80,20, function() svcReroll() end)
btnReroll:SetPoint("TOPRIGHT",left,"TOPRIGHT",-10,-182)
btnReroll:Hide()

local actionLine=T:Font(left,12,"")
actionLine:SetPoint("TOPLEFT",left,"TOPLEFT",10,-186)
actionLine:SetPoint("TOPRIGHT",btnReroll,"TOPLEFT",-8,0)
actionLine:SetText("")

local reasonLine=T:Font(left,11,"")
reasonLine:SetPoint("TOPLEFT",actionLine,"BOTTOMLEFT",0,-6)
reasonLine:SetPoint("TOPRIGHT",actionLine,"BOTTOMRIGHT",0,-6)
reasonLine:SetText("")

local progLabel=T:Font(right,12,"")
progLabel:SetPoint("TOPLEFT",right,"TOPLEFT",10,-40)
progLabel:SetPoint("TOPRIGHT",right,"TOPRIGHT",-10,-40)
progLabel:SetText("")

local progRun=CreateFrame("StatusBar",nil,right)
progRun:SetPoint("TOPLEFT",right,"TOPLEFT",10,-66)
progRun:SetPoint("TOPRIGHT",right,"TOPRIGHT",-10,-66)
progRun:SetHeight(16)
progRun:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
progRun:SetMinMaxValues(0,79)
progRun:SetValue(0)
progRun:SetStatusBarColor(c.aqua[1],c.aqua[2],c.aqua[3],0.85)
solid(progRun,"BACKGROUND",0.02,0.03,0.05,0.75)
T:ApplyPanel(progRun,"navy")

local progRunTxt=T:Font(right,11,"")
progRunTxt:SetPoint("CENTER",progRun,"CENTER",0,0)
progRunTxt:SetJustifyH("CENTER")
progRunTxt:SetText("")

local progLvl=CreateFrame("StatusBar",nil,right)
progLvl:SetPoint("TOPLEFT",progRun,"BOTTOMLEFT",0,-16)
progLvl:SetPoint("TOPRIGHT",progRun,"BOTTOMRIGHT",0,-16)
progLvl:SetHeight(16)
progLvl:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
progLvl:SetMinMaxValues(2,80)
progLvl:SetValue(2)
progLvl:SetStatusBarColor(c.heirloom[1],c.heirloom[2],c.heirloom[3],0.75)
solid(progLvl,"BACKGROUND",0.02,0.03,0.05,0.75)
T:ApplyPanel(progLvl,"navy")

local progLvlTxt=T:Font(right,11,"")
progLvlTxt:SetPoint("CENTER",progLvl,"CENTER",0,0)
progLvlTxt:SetJustifyH("CENTER")
progLvlTxt:SetText("")

local sessLine1=T:Font(right,12,"")
sessLine1:SetPoint("TOPLEFT",progLvl,"BOTTOMLEFT",0,-20)
sessLine1:SetPoint("TOPRIGHT",right,"TOPRIGHT",-10,0)
sessLine1:SetText("")

local sessLine2=T:Font(right,12,"")
sessLine2:SetPoint("TOPLEFT",sessLine1,"BOTTOMLEFT",0,-4)
sessLine2:SetPoint("TOPRIGHT",sessLine1,"TOPRIGHT",0,0)
sessLine2:SetText("")

local sessLine3=T:Font(right,12,"")
sessLine3:SetPoint("TOPLEFT",sessLine2,"BOTTOMLEFT",0,-4)
sessLine3:SetPoint("TOPRIGHT",sessLine1,"TOPRIGHT",0,0)
sessLine3:SetText("")

local sessLine4=T:Font(right,12,"")
sessLine4:SetPoint("TOPLEFT",sessLine3,"BOTTOMLEFT",0,-4)
sessLine4:SetPoint("TOPRIGHT",sessLine1,"TOPRIGHT",0,0)
sessLine4:SetText("")

local function fmtTime(s)
  s=tonumber(s or 0) or 0
  if s<=0 then return "0:00" end
  local m=math.floor(s/60)
  local r=math.floor(s-(m*60))
  return string.format("%d:%02d",m,r)
end

local function reasonText(r)
  if r=="onlyBlacklisted" then return "Paused: Blacklisted / Negative Only" end
  if r=="multipleAbove" then return "Paused: Threshold Met" end
  if r=="sessionComplete" then return "Paused: Session Complete" end
  return "Paused"
end

function Page:_EA_RefreshLayout()
  local w=intro:GetWidth()
  if not w or w<=0 then return end
  local inner=w-20
  local usable=inner-2
  if usable<60 then usable=60 end
  local cw1=math.floor(usable*0.36)
  local cw2=math.floor(usable*0.34)
  local cw3=usable-cw1-cw2
  if cw3<60 then cw3=60 end
  if cw1<60 then cw1=60 end
  if cw2<60 then cw2=60 end
  local sum=cw1+cw2+cw3
  if sum~=usable then cw3=cw3+(usable-sum) end
  col1:SetWidth(cw1)
  col2:SetWidth(cw2)
  col3:SetWidth(cw3)
  local t1=col1:GetWidth()
  local t2=col2:GetWidth()
  local t3=col3:GetWidth()
  if t1 and t1>0 then i1Text:SetWidth(t1) end
  if t2 and t2>0 then i2Text:SetWidth(t2) end
  if t3 and t3>0 then i3Text:SetWidth(t3) end
end


local function update()
  local snap=nil
  if EA and EA.Engine and EA.Engine.GetUISnapshot then
    local ok,res=pcall(function() return EA.Engine:GetUISnapshot() end)
    if ok then snap=res end
  end
  if type(snap)~="table" then
    statusLeft:SetText("Engine: unavailable")
    statusRight:SetText("")
    if lRemain then lRemain:SetText("") end
    btnStart:Hide()
    btnStop:Hide()
    actionLine:SetText("Waiting for engine")
    reasonLine:SetText("")
    setChoiceRow(row1,nil)
    setChoiceRow(row2,nil)
    setChoiceRow(row3,nil)
    progLabel:SetText("")
    progRun:SetValue(0)
    progRunTxt:SetText("")
    progLvl:SetValue(2)
    progLvlTxt:SetText("")
    sessLine1:SetText("")
    sessLine2:SetText("")
    sessLine3:SetText("")
    sessLine4:SetText("")
    return
  end

  local enabled=snap.enabled==true
  if enabled then btnStart:Hide() else btnStart:Show() end
  if enabled then btnStop:Show() else btnStop:Hide() end

  local prName=""
  if EA and EA.Profiles and EA.Profiles.GetActiveProfile then
    local pr=EA.Profiles:GetActiveProfile()
    if pr and pr.name then prName=pr.name end
  end
  if prName=="" then prName="(no profile)" end

  local offerState="No offer"
  if snap.offer and type(snap.offer)=="table" and #snap.offer>0 then
    offerState="Offer seen"
  else
    if snap.sinceOffer~=nil then offerState=string.format("No offer (%.0fs)",tonumber(snap.sinceOffer) or 0) end
  end

  local leftTxt
  if enabled then
    leftTxt=string.format("Running | %s | Profile: %s",offerState,prName)
  else
    local prsn=snap.pausedReason
    if prsn then
      leftTxt=string.format("%s | %s | Profile: %s",reasonText(prsn),offerState,prName)
    else
      leftTxt=string.format("Stopped | %s | Profile: %s",offerState,prName)
    end
  end
  statusLeft:SetText(leftTxt)

  local rr=tonumber(snap.rerollsRemaining or 0) or 0
  local br=tonumber(snap.banishesRemaining or 0) or 0
  statusRight:SetText(string.format("Rerolls: %d  Banishes: %d",rr,br))
  if lRemain then
    lRemain:SetText(string.format("Remaining Banishes: %d\nRemaining Rerolls: %d",br,rr))
  end

  local offer=snap.offer
  local dec=snap.decision
  if offer and type(offer)=="table" and #offer>0 and dec and dec.scores then
    local s=dec.scores
    setChoiceRow(row1,s[1] and s[1].choice and {name=s[1].choice.name,icon=s[1].choice.icon,quality=s[1].choice.quality,score=s[1].score} or nil)
    setChoiceRow(row2,s[2] and s[2].choice and {name=s[2].choice.name,icon=s[2].choice.icon,quality=s[2].choice.quality,score=s[2].score} or nil)
    setChoiceRow(row3,s[3] and s[3].choice and {name=s[3].choice.name,icon=s[3].choice.icon,quality=s[3].choice.quality,score=s[3].score} or nil)
    local act=dec.action or ""
    local best=tonumber(dec.bestI or 0) or 0
    local ban=tonumber(dec.banishI or 0) or 0
    if act=="pick" and best>0 then
      actionLine:SetText(string.format("Planned: Pick option %d",best))
    elseif act=="reroll" then
      actionLine:SetText("Planned: Reroll")
    elseif act=="banish" and ban>0 then
      actionLine:SetText(string.format("Planned: Banish option %d",ban))
    elseif act=="pause" then
      actionLine:SetText("Planned: Pause")
    else
      actionLine:SetText("Planned: -")
    end
    reasonLine:SetText(dec.reason and ("Reason: "..tostring(dec.reason)) or "")
  else
    setChoiceRow(row1,nil)
    setChoiceRow(row2,nil)
    setChoiceRow(row3,nil)
    actionLine:SetText("Waiting for offer")
    reasonLine:SetText("")
  end

  local manualActive=(not enabled) and offer and type(offer)=="table" and #offer>0
  if manualActive then btnReroll:Show() else btnReroll:Hide() end
  if btnReroll.SetEnabled then btnReroll:SetEnabled(manualActive and rr>0) end
  if manualActive then
    local function bindRow(r,i)
      local o=offer[i]
      if o and o.spellId then
        r.btnSelect:Show()
        r.btnBanish:Show()
        r.btnSelect:SetScript("OnClick",function() svcSelect(tonumber(o.spellId) or 0) end)
        r.btnBanish:SetScript("OnClick",function() svcBanish(i-1) end)
        if r.btnSelect.SetEnabled then r.btnSelect:SetEnabled(true) end
        if r.btnBanish.SetEnabled then r.btnBanish:SetEnabled(br>0) end
      else
        r.btnSelect:Hide()
        r.btnBanish:Hide()
      end
    end
    bindRow(row1,1)
    bindRow(row2,2)
    bindRow(row3,3)
  else
    row1.btnSelect:Hide()
    row1.btnBanish:Hide()
    row2.btnSelect:Hide()
    row2.btnBanish:Hide()
    row3.btnSelect:Hide()
    row3.btnBanish:Hide()
  end


  local picks=tonumber(snap.picksCount or 0) or 0
  local el=tonumber(snap.echoLevel or 2) or 2
  progLabel:SetText(string.format("Player level %d | Picks %d/79",tonumber(snap.playerLevel or 0) or 0,picks))
  progRun:SetMinMaxValues(0,79)
  progRun:SetValue(math.max(0,math.min(79,picks)))
  progRunTxt:SetText(string.format("%d/79",math.max(0,math.min(79,picks))))

  local lvl=tonumber(snap.playerLevel or 0) or 0
  if lvl<2 then lvl=2 end
  if lvl>80 then lvl=80 end
  progLvl:SetMinMaxValues(2,80)
  progLvl:SetValue(lvl)
  progLvlTxt:SetText(string.format("Level %d/80",lvl))

  local s=nil
  if EA and EA.Run and EA.Run.GetSessionState then s=EA.Run:GetSessionState() end
  local sessionStr="Session: Not Started"
  local xphStr="XP / Hour: -"
  if s and s.active then
    local dur=(time and time() or 0)-(tonumber(s.startTime or 0) or 0)
    local xp=tonumber(s.totalXP or 0) or 0
    local a=tonumber(s.activeSeconds or 0) or 0
    local xph=0
    if a>0 then xph=(xp/(a/3600)) end
    sessionStr="Session: "..fmtTime(dur)
    xphStr="XP / Hour: "..tostring(math.floor(xph+0.5))
  else
    if s and s.completed then
      local dur=tonumber(s.completedDuration or 0) or 0
      local xp=tonumber(s.completedXP or 0) or 0
      local a=tonumber(s.completedActiveSeconds or 0) or 0
      local xph=0
      if a>0 then xph=(xp/(a/3600)) end
      sessionStr="Session: Completed in "..fmtTime(dur)
      xphStr="XP / Hour: "..tostring(math.floor(xph+0.5))
    end
  end
  local fastest=0
  local slowest=0
  if EchoArchitect_Logbook and EchoArchitect_Logbook.sessionHighlights then
    fastest=tonumber(EchoArchitect_Logbook.sessionHighlights.fastest or 0) or 0
    slowest=tonumber(EchoArchitect_Logbook.sessionHighlights.slowest or 0) or 0
  end
  local fastestStr="-"
  if fastest>0 then fastestStr=fmtTime(fastest) end
  local slowestStr="-"
  if slowest>0 then slowestStr=fmtTime(slowest) end
  sessLine1:SetText(sessionStr)
  sessLine2:SetText(xphStr)
  sessLine3:SetText("Fastest Session: "..fastestStr)
  sessLine4:SetText("Slowest Session: "..slowestStr)
end

Page._eaAcc=0
Page:SetScript("OnShow",function(self)
  self:_EA_RefreshLayout()
  local d=getDashDB() or {}
  if d.scale==nil then d.scale=nil end
  update()
  self._eaAcc=0
  self:SetScript("OnUpdate",function(_,el)
    Page._eaAcc=(Page._eaAcc or 0)+(tonumber(el) or 0)
    if Page._eaAcc<0.15 then return end
    Page._eaAcc=0
    update()
  end)
end)

Page:SetScript("OnHide",function(self)
  self:SetScript("OnUpdate",nil)
end)

Win:RegisterPage("dashboard",Page)