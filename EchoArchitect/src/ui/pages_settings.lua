local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
local UI=EA.UI
local Win=UI.Window
local W=UI.Widgets
local T=UI.Theme
local Page=CreateFrame("Frame",nil,UIParent)
T:ApplyPanel(Page,"bg")

local function pr()
  return EA.Profiles and EA.Profiles:GetActiveProfile() or nil
end

local function cdb()
  return EchoArchitect_CharDB
end

local hdr=W:Label(Page,"",16)
hdr:SetPoint("TOPLEFT",Page,"TOPLEFT",0,0)
hdr:Hide()
local left=CreateFrame("Frame",nil,Page)
left:SetPoint("TOPLEFT",Page,"TOPLEFT",0,0)
left:SetPoint("BOTTOMLEFT",Page,"BOTTOMLEFT",0,0)
left:SetWidth(420)
T:ApplyPanel(left,"navy")

local right=CreateFrame("Frame",nil,Page)
right:SetPoint("TOPLEFT",left,"TOPRIGHT",10,0)
right:SetPoint("BOTTOMRIGHT",Page,"BOTTOMRIGHT",0,0)
T:ApplyPanel(right,"navy")

local function ctx(p)
  return {p=p,y=-12}
end

local contentW=320
local function place(ctrl,parent,y)
  ctrl:ClearAllPoints()
  if ctrl.SetWidth then ctrl:SetWidth(contentW) end
  ctrl:SetPoint("TOP",parent,"TOP",0,y)
end

local function sep(C,txt)
  local h=W:Label(C.p,txt,14)
  h:SetJustifyH("CENTER")
  place(h,C.p,C.y)
  local line=C.p:CreateTexture(nil,"BORDER")
  line:SetTexture("Interface\Buttons\WHITE8X8")
  line:SetVertexColor(0.2,0.25,0.32,0.9)
  line:SetPoint("TOP",h,"BOTTOM",0,-8)
  line:SetWidth(contentW)
  line:SetHeight(1)
  C.y=C.y-36
  return h
end

local function addCheck(C,txt,get,set)
  local c=W:Check(C.p,txt,function(_,v)
    set(v)
  end)
  place(c,C.p,C.y)
  c._get=get
  C.y=C.y-26
  return c
end

local tabGeneral={}

local function addNum(C,txt,w,get,set)
  local row=CreateFrame("Frame",nil,C.p)
  row:SetWidth(contentW)
  row:SetHeight(22)
  row:SetPoint("TOP",C.p,"TOP",0,C.y)
  local l=W:Label(row,txt..":",12)
  l:SetPoint("LEFT",row,"LEFT",0,0)
  local e=W:EditBox(row,w or 70,20)
  tabGeneral[#tabGeneral+1]=e
  e:SetJustifyH("CENTER")
  e:SetPoint("RIGHT",row,"RIGHT",0,0)
  W:BindCommit(e,function(ed)
    local v=tonumber(ed:GetText() or "")
    if v~=nil then set(v) end
  end)
  e._get=get
  C.y=C.y-24
  return e
end

local function addSlider(C,txt,minV,maxV,step,get,set)
  local s=W:Slider(C.p,txt,minV,maxV,step,contentW,function(v) set(v) end)
  place(s,C.p,C.y)
  s._get=get
  C.y=C.y-46
  return s
end

local L=ctx(left)
local R=ctx(right)

local chkShowSS=addCheck(L,"Show Start/Stop Button",function() local p=pr() return p and p.automation.showStartStopButton end,function(v) local p=pr() if p then p.automation.showStartStopButton=v end if EA and EA.UI and EA.UI.StartStop and EA.UI.StartStop.Refresh then EA.UI.StartStop:Refresh() end end)
local chkHidePerks=addCheck(L,"Disable the Echoes Perk Frame While Running",function() local p=pr() return p and p.automation.hidePerkFrameWhileRunning end,function(v) local p=pr() if p then p.automation.hidePerkFrameWhileRunning=v end if EA and EA.Engine and EA.Engine.SyncPerkUI then EA.Engine:SyncPerkUI() end end)

local chkPick=addCheck(L,"Enable Picking",function() local p=pr() return p and p.automation.enablePick end,function(v) local p=pr() if p then p.automation.enablePick=v end end)
local chkReroll=addCheck(L,"Enable Rerolling",function() local p=pr() return p and p.automation.enableReroll end,function(v) local p=pr() if p then p.automation.enableReroll=v end end)
local chkBanish=addCheck(L,"Enable Banishing",function() local p=pr() return p and p.automation.enableBanish end,function(v) local p=pr() if p then p.automation.enableBanish=v end end)
local sSpeed=W:Slider(L.p,"Automation Speed",0.05,1.5,0.05,contentW,function(v) local p=pr() if p then p.automation.speed=v end end,function(v) return string.format("%.2f",v) end)
place(sSpeed,L.p,L.y)
sSpeed._get=function() local p=pr() return p and p.automation.speed end
L.y=L.y-46
local chkPauseMulti=addCheck(L,"Pause if 2+ options >= Threshold",function() local p=pr() return p and p.automation.pauseIfMultipleAbove end,function(v) local p=pr() if p then p.automation.pauseIfMultipleAbove=v end end)
local eThr=addNum(L,"Threshold",70,function() local p=pr() return p and p.automation.threshold end,function(v) local p=pr() if p then p.automation.threshold=v end end)
local chkPauseBlk=addCheck(L,"Pause if Only Blacklisted / Negative Weight",function() local p=pr() return p and p.automation.pauseIfOnlyBlacklisted end,function(v) local p=pr() if p then p.automation.pauseIfOnlyBlacklisted=v end end)
local function aggLabel(v)
  local n=tonumber(v or 0) or 0
  if n<=0 then return "None" end
  if n<=0.25 then return "Mild" end
  if n<=0.5 then return "Normal" end
  return "Aggressive"
end
local function aggToIndex(v)
  local n=tonumber(v or 0) or 0
  if n<=0 then return 0 end
  if n<=0.25 then return 1 end
  if n<=0.5 then return 2 end
  return 3
end
local function indexToAgg(i)
  i=tonumber(i or 0) or 0
  if i<=0 then return 0 end
  if i==1 then return 0.25 end
  if i==2 then return 0.5 end
  return 1
end
local sAgg=W:Slider(L.p,"Reroll Aggressiveness",0,3,1,contentW,function(i)
  local p=pr()
  if p then p.automation.aggressiveness=indexToAgg(i) end
end,function(i)
  return aggLabel(indexToAgg(i))
end)
place(sAgg,L.p,L.y)
sAgg._get=function() local p=pr() return p and aggToIndex(p.automation.aggressiveness) end
L.y=L.y-46
local sMaxCont=addSlider(L,"Max Continuous Rerolls",0,10,1,function() local p=pr() return p and p.automation.maxContinuousRerolls end,function(v) local p=pr() if p then p.automation.maxContinuousRerolls=v end end)
local sMinLvl=addSlider(L,"Minimum Level Before Rerolling",1,80,1,function() local p=pr() return p and p.automation.minLevelBeforeRerolling end,function(v) local p=pr() if p then p.automation.minLevelBeforeRerolling=v end end)
local rowMinKeep=CreateFrame("Frame",nil,L.p)
  rowMinKeep:SetWidth(contentW)
  rowMinKeep:SetHeight(22)
  rowMinKeep:SetPoint("TOP",L.p,"TOP",0,L.y)
  local lMinKeep=W:Label(rowMinKeep,"Only Reroll Below:",12)
  lMinKeep:SetPoint("LEFT",rowMinKeep,"LEFT",0,0)
  local eMinKeep=W:EditBox(rowMinKeep,70,20)
  eMinKeep:SetPoint("RIGHT",rowMinKeep,"RIGHT",0,0)
  local lWeight=W:Label(rowMinKeep,"Weight",12)
  lWeight:SetPoint("RIGHT",eMinKeep,"LEFT",-10,0)
W:BindCommit(eMinKeep,function(ed)
  local v=tonumber(ed:GetText() or "")
  local p=pr()
  if p and v~=nil then p.automation.minKeepScore=v end
end)
eMinKeep._get=function() local p=pr() return p and p.automation.minKeepScore end
L.y=L.y-24

local sOwnedPen=W:Slider(R.p,"Duplicate Echo Penalty",0,100,1,contentW,function(v)
  local p=pr()
  if p then p.scoring.ownedPenalty=v end
end,function(v)
  local n=math.floor((tonumber(v or 0) or 0)+0.5)
  return tostring(n).."%"
end)
place(sOwnedPen,R.p,R.y)
sOwnedPen._get=function()
  local p=pr()
  if not p then return 0 end
  local n=tonumber(p.scoring.ownedPenalty or 0) or 0
  if n<=1 then n=n*100 end
  return n
end
R.y=R.y-46

local grid=CreateFrame("Frame",nil,R.p)
grid:SetPoint("TOP",R.p,"TOP",0,R.y)
grid:SetWidth(contentW)
grid:SetHeight(170)

local gh=W:Label(grid,"Quality bonus / multiplier",12)
gh:SetPoint("TOPLEFT",grid,"TOPLEFT",0,0)

local qualities={
  {q=0,txt="Common"},
  {q=1,txt="Uncommon"},
  {q=2,txt="Rare"},
  {q=3,txt="Epic"},
  {q=4,txt="Legendary"},
}

local bonusEdits={}
local multEdits={}
local hb=W:Label(grid,"Bonus",12)
hb:SetPoint("TOPLEFT",grid,"TOPLEFT",150,-18)
local hm=W:Label(grid,"Multiplier",12)
hm:SetPoint("TOPLEFT",grid,"TOPLEFT",236,-18)

for i=1,#qualities do
  local q=qualities[i].q
  local col=EA.DB:QualityColor(q)
  local rowY=-18-(i*26)
  local t=W:Label(grid,col..qualities[i].txt.."|r",12)
  t:SetPoint("TOPLEFT",grid,"TOPLEFT",0,rowY)
  local b=W:EditBox(grid,70,20)
  b:SetPoint("TOPLEFT",grid,"TOPLEFT",150,rowY+2)
  W:BindCommit(b,function(ed)
    local p=pr()
    if not p then return end
    local v=tonumber(ed:GetText() or "")
    if v~=nil then p.scoring.qualityBonus[q]=v end
  end)
  bonusEdits[q]=b
  local m=W:EditBox(grid,70,20)
  m:SetPoint("TOPLEFT",grid,"TOPLEFT",236,rowY+2)
  W:BindCommit(m,function(ed)
    local p=pr()
    if not p then return end
    local v=tonumber(ed:GetText() or "")
    if v~=nil then p.scoring.qualityMultiplier[q]=v end
  end)
  multEdits[q]=m
end

local function getUIScale()
  local db=cdb()
  local s=db and db.ui and db.ui.window and tonumber(db.ui.window.scale)
  if not s or s<=0 then s=1 end
  return s
end

local function setUIScale(v)
  local db=cdb()
  if not db then return end
  db.ui=db.ui or {}
  db.ui.window=db.ui.window or {}
  db.ui.window.scale=v
  local f=EA and EA.UI and EA.UI.Window and EA.UI.Window.frame
  if f and f.SetScale then f:SetScale(v) end
end

R.y=R.y-190

local uiScaleMin=0.7
local uiScaleMax=1.3
local uiScaleStep=0.05
local sliderW=contentW-64
if sliderW<180 then sliderW=180 end
local sUIScale=W:Slider(R.p,"UI Scale",uiScaleMin,uiScaleMax,uiScaleStep,sliderW,function() end,function(v) return string.format("%.2f",v) end)
place(sUIScale,R.p,R.y)
R.y=R.y-24
sUIScale._get=function() return getUIScale() end

R.y=R.y-24
sep(R,"Start/Stop Button Texts")
local chkRemEchoes=addCheck(R,"Remaining Echoes",function()
  local p=pr() return p and p.automation and p.automation.showStartStopRemainingEchoes~=false
end,function(v)
  local p=pr() if not p then return end
  p.automation=p.automation or {}
  p.automation.showStartStopRemainingEchoes=v
  if EA and EA.UI and EA.UI.StartStop and EA.UI.StartStop.Refresh then EA.UI.StartStop:Refresh() end
end)

local chkRemRerolls=addCheck(R,"Remaining Rerolls",function()
  local p=pr() return p and p.automation and p.automation.showStartStopRemainingRerolls~=false
end,function(v)
  local p=pr() if not p then return end
  p.automation=p.automation or {}
  p.automation.showStartStopRemainingRerolls=v
  if EA and EA.UI and EA.UI.StartStop and EA.UI.StartStop.Refresh then EA.UI.StartStop:Refresh() end
end)
local chkRemBanishes=addCheck(R,"Remaining Banishes",function()
  local p=pr() return p and p.automation and p.automation.showStartStopRemainingBanishes~=false
end,function(v)
  local p=pr() if not p then return end
  p.automation=p.automation or {}
  p.automation.showStartStopRemainingBanishes=v
  if EA and EA.UI and EA.UI.StartStop and EA.UI.StartStop.Refresh then EA.UI.StartStop:Refresh() end
end)

local function clampUIScale(v)
  v=tonumber(v or 1) or 1
  if v<uiScaleMin then v=uiScaleMin end
  if v>uiScaleMax then v=uiScaleMax end
  local n=math.floor((v-uiScaleMin)/uiScaleStep+0.5)
  return uiScaleMin+n*uiScaleStep
end
local function applyUIScale(v)
  v=clampUIScale(v)
  setUIScale(v)
  if sUIScale and sUIScale.SetValue then sUIScale:SetValue(v) end
end

if sUIScale and sUIScale._bar then
  local bar=sUIScale._bar
  bar:EnableMouse(false)
  bar:EnableMouseWheel(false)
  bar:SetScript("OnMouseDown",nil)
  bar:SetScript("OnMouseUp",nil)
  bar:SetScript("OnMouseWheel",nil)
  local knob=select(1,bar:GetChildren())
  if knob then
    knob:EnableMouse(false)
    knob:SetScript("OnMouseDown",nil)
    knob:SetScript("OnMouseUp",nil)
  end
end
if sUIScale then
  sUIScale:EnableMouse(false)
  sUIScale:SetScript("OnMouseUp",nil)
  sUIScale:SetScript("OnUpdate",nil)
end

local bMinus=W:Button(R.p,"-",28,18,function()
  applyUIScale(getUIScale()-uiScaleStep)
end)
local bPlus=W:Button(R.p,"+",28,18,function()
  applyUIScale(getUIScale()+uiScaleStep)
end)
if sUIScale and sUIScale._bar then
  bMinus:SetPoint("LEFT",sUIScale._bar,"RIGHT",6,0)
  bPlus:SetPoint("LEFT",bMinus,"RIGHT",4,0)
else
  bMinus:SetPoint("TOPRIGHT",sUIScale,"TOPRIGHT",-32,-22)
  bPlus:SetPoint("LEFT",bMinus,"RIGHT",4,0)
end

R.y=R.y-46

local function applyTabOrder()
  local order={}
  for i=1,#tabGeneral do order[#order+1]=tabGeneral[i] end
  for q=0,4 do if bonusEdits[q] then order[#order+1]=bonusEdits[q] end end
  for q=0,4 do if multEdits[q] then order[#order+1]=multEdits[q] end end
  for i=1,#order do
    local ed=order[i]
    if ed and ed.SetScript then
      local ii=i
      ed:SetScript("OnTabPressed",function(self)
        local dir=IsShiftKeyDown() and -1 or 1
        local ni=ii+dir
        if ni<1 then ni=#order end
        if ni>#order then ni=1 end
        local nxt=order[ni]
        if nxt and nxt.SetFocus then
          nxt:SetFocus()
          nxt:HighlightText()
        end
      end)
    end
  end
end

applyTabOrder()

local function refresh()
  local p=pr()
  if not p then return end
  chkShowSS:SetValue(p.automation.showStartStopButton~=false)
  chkHidePerks:SetValue(p.automation.hidePerkFrameWhileRunning)
  chkPick:SetValue(p.automation.enablePick)
  chkReroll:SetValue(p.automation.enableReroll)
  if chkRemEchoes then chkRemEchoes:SetValue(p.automation.showStartStopRemainingEchoes~=false) end
  if chkRemRerolls then chkRemRerolls:SetValue(p.automation.showStartStopRemainingRerolls~=false) end
  if chkRemBanishes then chkRemBanishes:SetValue(p.automation.showStartStopRemainingBanishes~=false) end
  chkBanish:SetValue(p.automation.enableBanish)
  sSpeed:SetValue(p.automation.speed)
  chkPauseMulti:SetValue(p.automation.pauseIfMultipleAbove)
  eThr._eaSetting=true
  eThr:SetText(tostring(p.automation.threshold or 0))
  eThr._eaSetting=false
  chkPauseBlk:SetValue(p.automation.pauseIfOnlyBlacklisted)
  sAgg:SetValue(aggToIndex(p.automation.aggressiveness or 0))
  sMaxCont:SetValue(p.automation.maxContinuousRerolls or 0)
  sMinLvl:SetValue(p.automation.minLevelBeforeRerolling or 1)
  eMinKeep._eaSetting=true
  eMinKeep:SetText(tostring(p.automation.minKeepScore or 0))
  eMinKeep._eaSetting=false
  local op=tonumber(p.scoring.ownedPenalty or 0) or 0
  if op<=1 then op=op*100 end
  sOwnedPen:SetValue(op)
  for q=0,4 do
    if bonusEdits[q] then bonusEdits[q]._eaSetting=true bonusEdits[q]:SetText(tostring(p.scoring.qualityBonus[q] or 0)) bonusEdits[q]._eaSetting=false end
    if multEdits[q] then multEdits[q]._eaSetting=true multEdits[q]:SetText(tostring(p.scoring.qualityMultiplier[q] or 1)) multEdits[q]._eaSetting=false end
  end
  if sUIScale and sUIScale.SetValue then sUIScale:SetValue(getUIScale()) end
end

Page:SetScript("OnShow",refresh)
Win:RegisterPage("settings",Page)
