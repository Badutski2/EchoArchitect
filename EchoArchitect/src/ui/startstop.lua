local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.UI=EA.UI or {}
local UI=EA.UI
local T=UI.Theme
local W=UI.Widgets
local c=(T and T.c) or {navy={0.05,0.08,0.14,1},line={0.12,0.14,0.18,1},aqua={0.10,0.85,0.90,1},text={1,1,1,1}}
UI.StartStop=UI.StartStop or {}
local SS=UI.StartStop
local function db()
  return EchoArchitect_CharDB
end
local function pr()
  return EA.Profiles and EA.Profiles:GetActiveProfile() or nil
end
local function getRunData()
  if ProjectEbonhold and ProjectEbonhold.PlayerRunService and ProjectEbonhold.PlayerRunService.Get then
    local ok,rd=pcall(ProjectEbonhold.PlayerRunService.Get)
    if ok and type(rd)=="table" then return rd end
  end
  if _G and _G.EbonholdPlayerRunData then return _G.EbonholdPlayerRunData end
  return {}
end
local function echoesRemaining()
  local lvl=UnitLevel and UnitLevel("player") or 0
  local offered=math.min(80,math.max(0,(tonumber(lvl) or 0)-1))
  local run=EA.Run and EA.Run.GetRun and EA.Run:GetRun() or nil
  local picks=run and tonumber(run.picksCount or 0) or 0
  if picks>offered then picks=offered end
  local rem=offered-picks
  if rem<0 then rem=0 end
  return rem
end
local function rerollsRemaining(p)
  local rd=getRunData()
  local remField=tonumber(rd.remainingRerolls or rd.rerollsRemaining or rd.rerollsLeft or rd.rerollCharges or 0) or 0
  if remField>0 then return remField end
  local used=tonumber(rd.usedRerolls or rd.rerollsUsed or 0) or 0
  local total=tonumber(rd.totalRerolls or rd.rerollsTotal or 0) or 0
  if total>0 then
    local rem=total-used
    if rem<0 then rem=0 end
    return rem
  end
  local maxRow=p and p.automation and tonumber(p.automation.maxRerollsPerOffer) or nil
  if not maxRow then maxRow=10 end
  local thisOffer=EA.Engine and EA.Engine.state and tonumber(EA.Engine.state.rerollsThisOffer or 0) or 0
  local rem=maxRow-thisOffer
  if rem<0 then rem=0 end
  return rem
end
local function banishesRemaining()
  if not (ProjectEbonhold and ProjectEbonhold.Constants and ProjectEbonhold.Constants.ENABLE_BANISH_SYSTEM) then return 0 end
  local rd=getRunData()
  return tonumber(rd.remainingBanishes or 0) or 0
end

local function reasonText(r)
  if r=="onlyBlacklisted" then return "Paused: Blacklisted / Negative Only" end
  if r=="multipleAbove" then return "Paused: Threshold Met" end
  if r=="sessionComplete" then return "Paused: Session Complete" end
  return "Paused"
end
function SS:Create()
  if self.frame then return self.frame end
  local f=CreateFrame("Frame","EchoArchitectStartStopFrame",UIParent)
  f:SetWidth(236)
  f:SetHeight(40)
  f:SetPoint("TOP",UIParent,"TOP",0,-24)
  f:SetFrameStrata("MEDIUM")
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(false)
  local drag=CreateFrame("Button",nil,f)
  drag:SetWidth(236)
  drag:SetHeight(14)
  drag:SetPoint("TOP",f,"TOP",0,0)
  drag:EnableMouse(true)
  drag:RegisterForClicks("RightButtonDown","RightButtonUp")
  local dragbg=drag:CreateTexture(nil,"BACKGROUND")
  dragbg:SetAllPoints(drag)
  dragbg:SetTexture("Interface\\Buttons\\WHITE8X8")
  dragbg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.22)
  local title=T:Font(drag,11,"OUTLINE")
  title:SetPoint("CENTER",drag,"CENTER",0,0)
  title:SetJustifyH("CENTER")
  title:SetText("Echo Architect")
  drag:SetScript("OnMouseDown",function(_,btn)
    if btn~="RightButton" then return end
    f._dragging=true
    f:StartMoving()
  end)
  drag:SetScript("OnMouseUp",function(_,btn)
    if btn~="RightButton" then return end
    f:StopMovingOrSizing()
    f._dragging=false
    local d=db()
    d.ui=d.ui or {}
    d.ui.startStop=d.ui.startStop or {}
    local point,_,relPoint,x,y=f:GetPoint()
    d.ui.startStop.point=point
    d.ui.startStop.relPoint=relPoint
    d.ui.startStop.x=x
    d.ui.startStop.y=y
  end)
  local btn=CreateFrame("Button",nil,f)
  btn:SetWidth(236)
  btn:SetHeight(24)
  local bg=btn:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(btn)
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.40)
  btn._bg=bg
  local bt=btn:CreateTexture(nil,"BORDER")
  bt:SetTexture("Interface\\Buttons\\WHITE8X8")
  bt:SetVertexColor(c.line[1],c.line[2],c.line[3],0.85)
  bt:SetPoint("TOPLEFT",btn,"TOPLEFT",-1,1)
  bt:SetPoint("BOTTOMRIGHT",btn,"BOTTOMRIGHT",1,-1)
  btn._border=bt
  btn:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local ht=btn:GetHighlightTexture()
  if ht then ht:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.12) end
  btn:SetScript("OnEnter",function() btn._bg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.55) end)
  btn:SetScript("OnLeave",function() btn._bg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.40) end)
  local label=T:Font(btn,14,"OUTLINE")
  label:SetPoint("CENTER",btn,"CENTER",0,0)
  label:SetJustifyH("CENTER")
  label:SetText("Start Echo Automation")
  btn._label=label
  function btn:SetText(t) self._label:SetText(t or "") end
  function btn:GetText() return self._label:GetText() end
  btn:SetScript("OnClick",function()
    if EA and EA.Engine and EA.Engine.state and EA.Engine.state.enabled then
      EA.Engine.state.pausedReason=nil
      EA.Engine:SetEnabled(false)
    else
      if EA and EA.Engine and EA.Engine.state then EA.Engine.state.pausedReason=nil end
      if EA and EA.Engine then EA.Engine:SetEnabled(true) end
    end
    SS:Refresh()
  end)
  btn:SetPoint("TOP",drag,"BOTTOM",0,-2)
  local sub=T:Font(f,10,"OUTLINE")
  sub:SetPoint("TOP",btn,"BOTTOM",0,-2)
  sub:SetText("")
  sub:SetJustifyH("CENTER")
  self.frame=f
  self.btn=btn
  self.drag=drag
  self.sub=sub
  self._acc=0
  f:SetScript("OnUpdate",function(_,el)
    SS._acc=(SS._acc or 0)+(tonumber(el) or 0)
    if SS._acc<0.2 then return end
    SS._acc=0
    SS:Refresh()
  end)
  self:Refresh()
  return f
end
function SS:Refresh()
  if not self.frame then return end
  local p=pr()
  local show=p and p.automation and p.automation.showStartStopButton
  if show==nil then show=true end
  if not show then
    self.frame:Hide()
    return
  end
  self.frame:Show()
  local d=db()
  if not self.frame._dragging and d and d.ui and d.ui.startStop and d.ui.startStop.x and d.ui.startStop.y then
    self.frame:ClearAllPoints()
    self.frame:SetPoint(d.ui.startStop.point or "TOP",UIParent,d.ui.startStop.relPoint or "TOP",d.ui.startStop.x,d.ui.startStop.y)
  end
  local eng=EA and EA.Engine and EA.Engine.state
  local enabled=eng and eng.enabled
  local prsn=eng and eng.pausedReason or nil
  local countsStr=""
  local a=p and p.automation or nil
  local showE=a==nil or a.showStartStopRemainingEchoes~=false
  local showP=a==nil or a.showStartStopRemainingRerolls~=false
  local showB=a==nil or a.showStartStopRemainingBanishes~=false
  if showE or showP or showB then
    local parts={}
    if showE then parts[#parts+1]="|cff9aa0a6Remaining Echoes:|r |cffffffff"..tostring(echoesRemaining()).."|r" end
    if showP then parts[#parts+1]="|cff9aa0a6Remaining Rerolls:|r |cffffffff"..tostring(rerollsRemaining(p)).."|r" end
    if showB then parts[#parts+1]="|cff9aa0a6Remaining Banishes:|r |cffffffff"..tostring(banishesRemaining()).."|r" end
    countsStr=table.concat(parts,"  |cff9aa0a6•|r  ")
  end
  if enabled then
    self.btn:SetText("Stop Echo Automation")
    if self.btn._label and self.btn._label.SetTextColor then self.btn._label:SetTextColor(1,0.28,0.28,1) end
    if countsStr~="" then self.sub:SetText(countsStr) self.frame:SetHeight(56) else self.sub:SetText("") self.frame:SetHeight(40) end
  else
    self.btn:SetText("Start Echo Automation")
    if self.btn._label and self.btn._label.SetTextColor then self.btn._label:SetTextColor(0.35,1,0.55,1) end
    if prsn then
      local r=reasonText(prsn)
      local msg=r
      local colon=string.find(r,":")
      if colon then
        local a=string.sub(r,1,colon)
        local b=string.sub(r,colon+1)
        msg="|cffffb24a"..a.."|r|cffffffff"..b.."|r"
      else
        msg="|cffffb24aPaused:|r |cffffffff"..r.."|r"
      end
      if countsStr~="" then self.sub:SetText(msg.."\n"..countsStr) self.frame:SetHeight(70) else self.sub:SetText(msg) self.frame:SetHeight(56) end
    else
      if countsStr~="" then self.sub:SetText(countsStr) self.frame:SetHeight(56) else self.sub:SetText("") self.frame:SetHeight(40) end
    end
  end
end
