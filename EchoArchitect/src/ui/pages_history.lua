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

local GAP=4
local ICON_W=18
local ICON_GAP=6
local START_X=10
local LIST_RIGHT_INSET=26
local LEVEL_W=80
local REROLLS_W=100
local NAME_W=560-START_X-LEVEL_W-REROLLS_W-(GAP*2)-LIST_RIGHT_INSET-10

local left=CreateFrame("Frame",nil,Page)
left:SetPoint("TOPLEFT",Page,"TOPLEFT",0,0)
left:SetPoint("BOTTOMLEFT",Page,"BOTTOMLEFT",0,0)
left:SetWidth(560)
T:ApplyPanel(left,"navy")

local right=CreateFrame("Frame",nil,Page)
right:SetPoint("TOPLEFT",left,"TOPRIGHT",10,0)
right:SetPoint("BOTTOMRIGHT",Page,"BOTTOMRIGHT",0,0)
T:ApplyPanel(right,"navy")

local hdr=W:Label(left,"",16)
hdr:SetPoint("TOPLEFT",left,"TOPLEFT",10,-10)
hdr:Hide()

local function QualityName(q)
  q=tonumber(q or 0) or 0
  if q==0 then return "Common" end
  if q==1 then return "Uncommon" end
  if q==2 then return "Rare" end
  if q==3 then return "Epic" end
  if q==4 then return "Legendary" end
  return "Unknown"
end

local searchLabel=W:Label(left,"Search",12)
searchLabel:SetPoint("TOPLEFT",left,"TOPLEFT",10,-10)
local searchBox=W:EditBox(left,240,20)
searchBox:SetPoint("LEFT",searchLabel,"RIGHT",8,0)
searchBox:SetScript("OnTextChanged",function()
  Page._search=searchBox:GetText() or ""
  Page:UpdateList(true)
end)

local function sortState()
  local cdb=EchoArchitect_CharDB
  cdb.ui=cdb.ui or {}
  cdb.ui.history=cdb.ui.history or {}
  local s=cdb.ui.history
  if not s.sortKey then s.sortKey="level" end
  if s.sortAsc==nil then s.sortAsc=true end
  return s
end

local headers=CreateFrame("Frame",nil,left)
headers:SetPoint("TOPLEFT",searchLabel,"BOTTOMLEFT",0,-10)
headers:SetPoint("TOPRIGHT",left,"TOPRIGHT",-LIST_RIGHT_INSET,0)
headers:SetHeight(18)

local function toggleSort(k)
  local s=sortState()
  if s.sortKey==k then s.sortAsc=not s.sortAsc else s.sortKey=k s.sortAsc=true end
  if scroll then FauxScrollFrame_SetOffset(scroll,0) end
  Page:UpdateList(true)
end

local hLevel=W:Button(headers,"Level",LEVEL_W,18,function() toggleSort("level") end)
hLevel:SetPoint("LEFT",headers,"LEFT",START_X,0)
if hLevel._fs then hLevel._fs:SetJustifyH("CENTER") end

local hName=W:Button(headers,"Name",NAME_W,18,function() toggleSort("name") end)
hName:SetPoint("LEFT",hLevel,"RIGHT",GAP,0)
if hName._fs then hName._fs:SetJustifyH("CENTER") end

local hRerolls=W:Button(headers,"Rerolls",REROLLS_W,18,function() toggleSort("rerolls") end)
hRerolls:SetPoint("LEFT",hName,"RIGHT",GAP,0)
if hRerolls._fs then hRerolls._fs:SetJustifyH("CENTER") end

local list=CreateFrame("Frame",nil,left)
list:SetPoint("TOPLEFT",headers,"BOTTOMLEFT",0,-8)
list:SetPoint("BOTTOMRIGHT",left,"BOTTOMRIGHT",-LIST_RIGHT_INSET,10)

local colSep=CreateFrame("Frame",nil,left)
colSep:SetPoint("TOPLEFT",headers,"TOPLEFT",0,0)
colSep:SetPoint("BOTTOMRIGHT",list,"BOTTOMRIGHT",0,0)

local SEP1=START_X+LEVEL_W+(GAP/2)
local SEP2=SEP1+(GAP/2)+GAP+NAME_W

local function vline(x)
  local t=colSep:CreateTexture(nil,"BORDER")
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  local lc=T.c.line
  t:SetVertexColor(lc[1],lc[2],lc[3],0.6)
  t:SetPoint("TOPLEFT",colSep,"TOPLEFT",x,0)
  t:SetPoint("BOTTOMLEFT",colSep,"BOTTOMLEFT",x,0)
  t:SetWidth(1)
  return t
end
local _seps={vline(SEP1),vline(SEP2)}
local function _UpdateSeps()
  local base=colSep:GetLeft()
  if not base then return end
  local function mid(a,b)
    if not a or not b then return nil end
    local ar=a:GetRight()
    local bl=b:GetLeft()
    if not ar or not bl then return nil end
    return (ar+bl)/2
  end
  local function setLine(t,midX)
    if not t or not midX then return end
    local x=midX-base
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT",colSep,"TOPLEFT",x,0)
    t:SetPoint("BOTTOMLEFT",colSep,"BOTTOMLEFT",x,0)
  end
  setLine(_seps[1],mid(hLevel,hName))
  setLine(_seps[2],mid(hName,hRerolls))
end

local emptyMsg=W:Label(left,"You should probably start getting some levels under your belt",14)
emptyMsg:SetPoint("CENTER",list,"CENTER",0,0)
emptyMsg:SetJustifyH("CENTER")
emptyMsg:SetTextColor(0.8,0.85,0.95,0.85)

local scroll=CreateFrame("ScrollFrame","EchoArchitectHistoryScroll",left,"FauxScrollFrameTemplate")
scroll:ClearAllPoints()
scroll:SetPoint("TOP",list,"TOP",0,0)
scroll:SetPoint("BOTTOM",list,"BOTTOM",0,0)
scroll:SetPoint("LEFT",list,"RIGHT",6,0)
scroll:SetPoint("RIGHT",left,"RIGHT",-10,0)
scroll:SetScript("OnVerticalScroll",function(self,offset)
  FauxScrollFrame_OnVerticalScroll(self,offset,26,function() Page:UpdateList(false) end)
end)

local lsb=_G[scroll:GetName().."ScrollBar"]
if lsb then
  lsb:ClearAllPoints()
  lsb:SetPoint("TOPLEFT",scroll,"TOPLEFT",0,0)
  lsb:SetPoint("BOTTOMLEFT",scroll,"BOTTOMLEFT",0,0)
  T:ApplyScrollBar(lsb)
  lsb:Show()
end

list:EnableMouseWheel(true)
scroll:EnableMouseWheel(true)
local function wheel(delta)
  local sb=_G[scroll:GetName().."ScrollBar"]
  if sb and sb.GetValue and sb.SetValue then
    local v=tonumber(sb:GetValue() or 0) or 0
    sb:SetValue(v-(delta*26*3))
  end
end
list:SetScript("OnMouseWheel",function(_,delta) wheel(delta) end)
scroll:SetScript("OnMouseWheel",function(_,delta) wheel(delta) end)

local function ShowSpellTooltip(owner,spellId)
  if not GameTooltip or not spellId or spellId==0 then return end
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
  if GameTooltip.SetSpellByID then
    GameTooltip:SetSpellByID(spellId)
  elseif GameTooltip.SetHyperlink then
    GameTooltip:SetHyperlink("spell:"..tostring(spellId))
  elseif GameTooltip.SetText then
    local name=GetSpellInfo and GetSpellInfo(spellId)
    if name then GameTooltip:SetText(name) end
  end
  GameTooltip:Show()
end

local ROWS=16
local rows={}
for i=1,ROWS do
  local r=CreateFrame("Button",nil,list)
  r:SetHeight(24)
  r:SetPoint("TOPLEFT",list,"TOPLEFT",0,-(i-1)*26)
  r:SetPoint("TOPRIGHT",list,"TOPRIGHT",0,-(i-1)*26)
  local bg=r:CreateTexture(nil,"BACKGROUND")
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetPoint("TOPLEFT",r,"TOPLEFT",0,0)
  bg:SetPoint("BOTTOMRIGHT",r,"BOTTOMRIGHT",0,0)
  bg:SetVertexColor(0,0,0,0)
  r:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local ht=r:GetHighlightTexture()
  if ht then ht:SetVertexColor(T.c.aqua[1],T.c.aqua[2],T.c.aqua[3],0.12) end

  local lvlBox=CreateFrame("Frame",nil,r)
  lvlBox:SetSize(LEVEL_W,20)
  lvlBox:SetPoint("LEFT",r,"LEFT",START_X,0)
  T:ApplyPanel(lvlBox,"navy")
  local lvlFs=T:Font(lvlBox,12,"")
  lvlFs:SetPoint("CENTER",lvlBox,"CENTER",0,0)
  lvlFs:SetWidth(LEVEL_W-6)
  lvlFs:SetJustifyH("CENTER")

  local nameBox=CreateFrame("Frame",nil,r)
  nameBox:SetSize(NAME_W,20)
  nameBox:SetPoint("LEFT",lvlBox,"RIGHT",GAP,0)
  T:ApplyPanel(nameBox,"navy")
  local icon=nameBox:CreateTexture(nil,"ARTWORK")
  icon:SetSize(18,18)
  icon:SetPoint("LEFT",nameBox,"LEFT",6,0)
  local nameFs=T:Font(nameBox,12,"")
  nameFs:SetPoint("LEFT",icon,"RIGHT",ICON_GAP,0)
  nameFs:SetPoint("RIGHT",nameBox,"RIGHT",-6,0)
  nameFs:SetJustifyH("CENTER")

  local rrBox=CreateFrame("Frame",nil,r)
  rrBox:SetSize(REROLLS_W,20)
  rrBox:SetPoint("LEFT",nameBox,"RIGHT",GAP,0)
  T:ApplyPanel(rrBox,"navy")
  local rrFs=T:Font(rrBox,12,"")
  rrFs:SetPoint("CENTER",rrBox,"CENTER",0,0)
  rrFs:SetWidth(REROLLS_W-6)
  rrFs:SetJustifyH("CENTER")

  r._bg=bg
  r._icon=icon
  r._lvl=lvlFs
  r._name=nameFs
  r._rr=rrFs
  r._lvlBox=lvlBox
  r._nameBox=nameBox
  r._rrBox=rrBox
  rows[i]=r
end

local detWrap=CreateFrame("Frame",nil,right)
detWrap:SetPoint("TOPLEFT",right,"TOPLEFT",10,-10)
detWrap:SetPoint("BOTTOMRIGHT",right,"BOTTOMRIGHT",-10,10)
T:ApplyPanel(detWrap,"bg")

local detScroll=CreateFrame("ScrollFrame","EchoArchitectHistoryDetailScroll",detWrap,"UIPanelScrollFrameTemplate")
detScroll:SetPoint("TOPLEFT",detWrap,"TOPLEFT",4,-4)
detScroll:SetPoint("BOTTOMRIGHT",detWrap,"BOTTOMRIGHT",-28,4)
local dsb=_G[detScroll:GetName().."ScrollBar"]
if dsb then T:ApplyScrollBar(dsb) end

local det=CreateFrame("EditBox",nil,detScroll)
det:SetMultiLine(true)
det:SetAutoFocus(false)
det:SetFont(STANDARD_TEXT_FONT,12,"")
det:SetWidth(1)
det:SetHeight(2000)
det:SetTextInsets(6,6,6,6)
det:SetScript("OnEscapePressed",function() det:ClearFocus() end)
det:SetScript("OnCursorChanged",function(_,x,y,w,h)
  detScroll:UpdateScrollChildRect()
  local curY=-y
  local viewH=detScroll:GetHeight() or 0
  local off=detScroll:GetVerticalScroll() or 0
  local range=detScroll:GetVerticalScrollRange() or 0
  local target=off
  if curY<off then target=curY end
  if curY+h>off+viewH then target=curY+h-viewH end
  if target<0 then target=0 end
  if target>range then target=range end
  if target~=off then detScroll:SetVerticalScroll(target) end
end)
detScroll:SetScrollChild(det)
detWrap:SetScript("OnSizeChanged",function()
  local w=(detScroll:GetWidth() or 1)-10
  if w<1 then w=1 end
  det:SetWidth(w)
  detScroll:UpdateScrollChildRect()
end)

local function buildDetail(e,hist,hi)
  if not e then return "" end
  local out={}
  local function add(s) out[#out+1]=s end
  local function addBlank() out[#out+1]="" end
  local d=type(e.decision)=="table" and e.decision or {}
  local offered=type(e.offered)=="table" and e.offered or {}
  local function collectPriorRerolls()
    local r={}
    if type(hist)~="table" or type(hi)~="number" then return r end
    local el=tonumber(e.echoLevel or 0) or 0
    for j=hi-1,1,-1 do
      local pe=hist[j]
      if not pe then break end
      local pel=tonumber(pe.echoLevel or 0) or 0
      if pel~=el then
        if pel<el and pe.action=="Pick" then break end
      else
        if pe.action=="Reroll" then r[#r+1]=pe end
      end
    end
    local n=#r
    for i=1,math.floor(n/2) do
      r[i],r[n-i+1]=r[n-i+1],r[i]
    end
    return r
  end
  local function fmtYN(t)
    if type(t)~="table" or #t==0 then return "(none)" end
    return table.concat(t,", ")
  end
  local function spellLine(o)
    if not o then return "" end
    local col=DB:QualityColor(o.quality)
    local nm=col..tostring(o.name or "").."|r"
    local sid=tostring(o.spellId or 0)
    local q=tostring(o.quality or 0)
    local w=tostring(o.weight or 0)
    local owned=tostring(o.owned or 0)
    local ms=tostring(o.maxStack or "")
    local bl=o.blacklisted and ("YES:"..tostring(o.blacklistReason or "")) or "no"
    local buck=""
    if o.bucketId then
      buck="  bucket="..tostring(o.bucketName or o.bucketId)
      if o.bucketCap and o.bucketCap>0 then buck=buck.." ("..tostring(o.bucketTotal or 0).."/"..tostring(o.bucketCap)..")" end
    end
    local sc=tostring(math.floor((tonumber(o.score or 0) or 0)*100)/100)
    local why=tostring(o.why or "")
    return nm.."\n    spellId="..sid.."  quality="..q.."  weight="..w.."  owned="..owned.."  maxStack="..ms.."  blacklisted="..bl..buck.."\n    score="..sc.."  why="..why
  end
  add("Time: "..tostring(e.t or 0))
  add("PlayerLevel: "..tostring(d.playerLevel or "?").."  RunStep: "..tostring(e.echoLevel or "?"))
  add("Action: "..tostring(e.action or "").."  Source: "..tostring(e.source or "").."  Reason: "..tostring(e.reason or ""))
  if d.offerHash and d.offerHash~="" then add("OfferHash: "..tostring(d.offerHash)) end
  add("RerollsLeft: "..tostring(e.rerollsLeft or 0).."  BanishesLeft: "..tostring(e.banishesLeft or 0).."  ContRerolls: "..tostring(d.contRerolls or 0).."  RerollsThisOffer: "..tostring(d.rerollsThisOffer or 0))
  addBlank()
  if e.action=="Pick" then
    local prior=collectPriorRerolls()
    if #prior>0 then
      add("Rerolled before pick: "..tostring(#prior))
      for i=1,#prior do
        local re=prior[i]
        local rd=type(re.decision)=="table" and re.decision or {}
        add("  Reroll #"..tostring(i).."  time="..tostring(re.t or 0).."  reason="..tostring(rd.actionReason or re.reason or ""))
        local ro=type(re.offered)=="table" and re.offered or {}
        add("  Offered before reroll:")
        for j=1,#ro do
          add("  "..tostring(j)..".")
          local sl=spellLine(ro[j])
          sl=string.gsub(sl,"\n","\n  ")
          add("  "..sl)
        end
      end
      addBlank()
    end
    local idx=tonumber(e.best or 0) or 0
    local o=offered[idx]
    add("Picked:")
    add(spellLine(o))
    addBlank()
    add("Why picked:")
    if type(d.bestScore)=="number" then
      add("    bestScore="..tostring(math.floor(d.bestScore*100)/100).."  effMinKeep="..tostring(math.floor((tonumber(d.effMinKeep or 0) or 0)*100)/100))
    else
      add("    bestScore=?  effMinKeep="..tostring(d.effMinKeep or 0))
    end
    add("    decision="..tostring(d.actionReason or e.reason or ""))
    addBlank()
    add("Why not reroll:")
    add("    "..fmtYN(d.whyNot and d.whyNot.reroll))
    add("Why not banish:")
    add("    "..fmtYN(d.whyNot and d.whyNot.banish))
  elseif e.action=="Banish" then
    local idx=tonumber(e.banishI or 0) or 0
    local o=offered[idx]
    add("Banished:")
    add(spellLine(o))
    addBlank()
    add("Why banished:")
    if o and o.blacklisted then
      add("    blacklisted="..tostring(o.blacklistReason or ""))
    else
      add("    banishReason="..tostring(e.reason or d.actionReason or ""))
    end
    addBlank()
    add("Why not pick:")
    add("    pickedBestIndex="..tostring(d.bestIndex or "").."  bestScore="..tostring(d.bestScore or ""))
    add("Why not reroll:")
    add("    "..fmtYN(d.whyNot and d.whyNot.reroll))
  elseif e.action=="Reroll" then
    add("Why reroll:")
    add("    "..tostring(d.actionReason or e.reason or ""))
    addBlank()
    add("Why not pick:")
    add("    bestScore="..tostring(d.bestScore or "").."  effMinKeep="..tostring(d.effMinKeep or ""))
    add("Why not banish:")
    add("    "..fmtYN(d.whyNot and d.whyNot.banish))
  else
    add("Decision context:")
    add("    whyNotReroll="..fmtYN(d.whyNot and d.whyNot.reroll))
    add("    whyNotBanish="..fmtYN(d.whyNot and d.whyNot.banish))
  end
  addBlank()
  add("Offered:")
  for i=1,#offered do
    add(tostring(i)..".")
    add(spellLine(offered[i]))
  end
  addBlank()
  add("Automation settings snapshot:")
  add("    enableReroll="..tostring(d.enableReroll or false).."  enableBanish="..tostring(d.enableBanish or false).."  threshold="..tostring(d.threshold or 0))
  add("    minKeepScore="..tostring(d.minKeepScore or 0).."  aggressiveness="..tostring(d.aggressiveness or 0).."  effMinKeep="..tostring(d.effMinKeep or 0))
  add("    minLevelBeforeRerolling="..tostring(d.minLevelBeforeRerolling or 1).."  maxContinuousRerolls="..tostring(d.maxContinuousRerolls or 0).."  maxRerollsPerOffer="..tostring(d.maxRerollsPerOffer or 10))
  add("    rerollsRemaining="..tostring(d.rerollsRemaining or 0).."/"..tostring(d.rerollsTotal or "").."  rerollsUsed="..tostring(d.rerollsUsed or "").."  banishesRemaining="..tostring(d.banishesRemaining or 0))
  addBlank()
  add("Stats snapshot:")
  if type(e.stats)=="table" then
    local parts={}
    for k,v in pairs(e.stats) do
      if v and v~=0 then parts[#parts+1]=tostring(k).."="..tostring(v) end
    end
    table.sort(parts)
    add(table.concat(parts,"  "))
  end
  return table.concat(out,"\n")
end

local function buildVisible(hist)
  local out={}
  local rr=0
  for i=1,#hist do
    local e=hist[i]
    if e and e.action=="Reroll" then
      rr=rr+1
    elseif e and (e.action=="Pick" or e.action=="Banish") then
      local idx=nil
      if e.action=="Pick" then idx=tonumber(e.best or 0) or 0 end
      if e.action=="Banish" then idx=tonumber(e.banishI or 0) or 0 end
      local pick=nil
      if idx and idx>0 and type(e.offered)=="table" then pick=e.offered[idx] end
      local n=#out+1 out[n]={e=e,rr=rr,p=pick,i=n,hi=i}
      if e.action=="Pick" then rr=0 end
    end
  end
  return out
end

local function applySearchAndSort(vis,query)
  query=string.lower(tostring(query or ""))
  local out={}
  if query=="" then
    for i=1,#vis do out[#out+1]=vis[i] end
  else
    for i=1,#vis do
      local v=vis[i]
      local e=v and v.e
      local p=v and v.p
      local nm=p and tostring(p.name or "") or ""
      local qn=p and QualityName(p.quality) or ""
      local act=e and tostring(e.action or "") or ""
      local hay=string.lower(nm.." "..qn.." "..act)
      if string.find(hay,query,1,true) then out[#out+1]=v end
    end
  end
  local s=sortState()
  local k=s.sortKey
  local asc=s.sortAsc and true or false
  table.sort(out,function(a,b)
    if a==b then return false end
    local ea=a and a.e
    local eb=b and b.e
    local ia=tonumber(a and a.i or 0) or 0
    local ib=tonumber(b and b.i or 0) or 0
    local asc2=asc and true or false
    if k=="level" then
      local la=(ea and tonumber(ea.echoLevel or 0)) or 0
      local lb=(eb and tonumber(eb.echoLevel or 0)) or 0
      if la<lb then return asc2 end
      if la>lb then return not asc2 end
    elseif k=="rerolls" then
      local ra=tonumber(a and a.rr or 0) or 0
      local rb=tonumber(b and b.rr or 0) or 0
      if ra<rb then return asc2 end
      if ra>rb then return not asc2 end
    else
      local na=string.lower(tostring((a and a.p and a.p.name) or ""))
      local nb=string.lower(tostring((b and b.p and b.p.name) or ""))
      if na<nb then return asc2 end
      if na>nb then return not asc2 end
    end
    local ta=(ea and tonumber(ea.t or 0)) or 0
    local tb=(eb and tonumber(eb.t or 0)) or 0
    if ta<tb then return true end
    if ta>tb then return false end
    return ia<ib
  end)
  return out
end

function Page:UpdateList(reset)
  local run=EA.Run and EA.Run.GetRun and EA.Run:GetRun() or {}
  local hist=run.history or {}
  local base=buildVisible(hist)
  self._vis=applySearchAndSort(base,self._search)
  local total=#(self._vis or {})
  if total==0 then emptyMsg:Show() else emptyMsg:Hide() end
  if not scroll then return end
  if reset then FauxScrollFrame_SetOffset(scroll,0) end
  FauxScrollFrame_Update(scroll,total,ROWS,26)
  local off=FauxScrollFrame_GetOffset(scroll)
  for i=1,ROWS do
    local idx=off+i
    local v=self._vis[idx]
    local r=rows[i]
    if v then
      local e=v.e
      r:Show()
      r._entry=e
      r._spellId=nil
      r._bg:SetVertexColor(0,0,0,0)
      r._lvl:SetText("Level "..tostring(e.echoLevel or "?"))
      local name="(unknown)"
      local icon=nil
      local q=nil
      if v.p then
        name=tostring(v.p.name or name)
        icon=v.p.icon or v.p.texture
        q=v.p.quality
        r._spellId=tonumber(v.p.spellId or 0) or 0
      end
      if icon then
        r._icon:SetTexture(icon)
        r._icon:Show()
      else
        r._icon:SetTexture(nil)
        r._icon:Hide()
      end
      local col=DB:QualityColor(q)
      local txt=col..name.."|r"
      if e.action=="Banish" then
        txt=txt.."  |cffff4040Banished|r"
      end
      r._name:SetText(txt)
      r._rr:SetText("Rerolls: "..tostring(v.rr or 0))
      r:SetScript("OnClick",function()
        det:SetText(buildDetail(e,hist,tonumber(v.hi or 0) or 0))
        detScroll:SetVerticalScroll(0)
      end)
      r:SetScript("OnEnter",function(self)
        self._bg:SetVertexColor(1,1,1,0.04)
        if self._spellId then ShowSpellTooltip(self,self._spellId) end
      end)
      r:SetScript("OnLeave",function(self)
        self._bg:SetVertexColor(0,0,0,0)
        if GameTooltip then GameTooltip:Hide() end
      end)
    else
      r:Hide()
    end
  end
end

Page:SetScript("OnShow",function() _UpdateSeps() Page:UpdateList(true) end)
Page:SetScript("OnSizeChanged",function() _UpdateSeps() end)
Win:RegisterPage("history",Page)