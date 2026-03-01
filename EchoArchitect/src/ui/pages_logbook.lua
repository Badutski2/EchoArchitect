local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
local UI=EA.UI
local Win=UI.Window
local W=UI.Widgets
local T=UI.Theme
local DB=EA.DB
local Log=EA.Logbook
local Page=CreateFrame("Frame",nil,UIParent)
T:ApplyPanel(Page,"bg")
local hdr=W:Label(Page,"",16)
hdr:SetPoint("TOPLEFT",Page,"TOPLEFT",0,0)
hdr:Hide()
local left=CreateFrame("Frame",nil,Page)
left:SetPoint("TOPLEFT",Page,"TOPLEFT",0,0)
left:SetPoint("BOTTOMLEFT",Page,"BOTTOMLEFT",0,0)
left:SetWidth(270)
T:ApplyPanel(left,"panel")
local right=CreateFrame("Frame",nil,Page)
right:SetPoint("TOPLEFT",left,"TOPRIGHT",10,0)
right:SetPoint("TOPRIGHT",Page,"TOPRIGHT",0,0)
right:SetPoint("BOTTOMRIGHT",Page,"BOTTOMRIGHT",0,0)
T:ApplyPanel(right,"panel")
local function qLabel(q)
  if q==0 then return "Common" end
  if q==1 then return "Uncommon" end
  if q==2 then return "Rare" end
  if q==3 then return "Epic" end
  if q==4 then return "Legendary" end
  return "Unknown"
end
local function pct(n,d)
  n=tonumber(n or 0) or 0
  d=tonumber(d or 0) or 0
  if d<=0 then return "0%" end
  return tostring(math.floor((n/d)*10000)/100).."%"
end
local function fmtTime(sec)
  sec=tonumber(sec or 0) or 0
  if sec<=0 then return "0" end
  local h=math.floor(sec/3600)
  local m=math.floor((sec%3600)/60)
  local s=math.floor(sec%60)
  if h>0 then return string.format("%dh %dm %ds",h,m,s) end
  if m>0 then return string.format("%dm %ds",m,s) end
  return string.format("%ds",s)
end

local function QualityName(q)
  q=tonumber(q or 0) or 0
  if q==0 then return "Common" end
  if q==1 then return "Uncommon" end
  if q==2 then return "Rare" end
  if q==3 then return "Epic" end
  if q==4 then return "Legendary" end
  return "Unknown"
end

local function sortState()
  local cdb=EchoArchitect_CharDB
  cdb.ui=cdb.ui or {}
  cdb.ui.logbook=cdb.ui.logbook or {}
  local s=cdb.ui.logbook
  if not s.sortKey then s.sortKey="seen" end
  if s.sortAsc==nil then s.sortAsc=false end
  return s
end
local function addKV(parent,y,label)
  local l=W:Label(parent,"|cff7fd6e8"..label.."|r",12)
  l:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-y)
  local v=W:Label(parent,"",12)
  v:SetPoint("TOPRIGHT",parent,"TOPRIGHT",0,-y)
  v:SetJustifyH("RIGHT")
  return v
end
local totalsHdr=W:Label(left,"Totals",13)
totalsHdr:SetPoint("TOPLEFT",left,"TOPLEFT",10,-10)
local totalsBox=CreateFrame("Frame",nil,left)
totalsBox:SetPoint("TOPLEFT",totalsHdr,"BOTTOMLEFT",0,-8)
totalsBox:SetPoint("TOPRIGHT",left,"TOPRIGHT",-10,0)
totalsBox:SetHeight(112)
local vSeen=addKV(totalsBox,0,"Echoes Seen:")
local vRuns=addKV(totalsBox,16,"Runs Completed:")
local vPicks=addKV(totalsBox,32,"Picks:")
local vRerolls=addKV(totalsBox,48,"Rerolls Used:")
local vBanishes=addKV(totalsBox,64,"Banishes Used:")
local vSSPM=addKV(totalsBox,80,"Shadowsteps / Min:")
local distHdr=W:Label(left,"Quality Distribution by Level",13)
distHdr:SetPoint("TOPLEFT",totalsBox,"BOTTOMLEFT",0,-16)
local distBox=CreateFrame("Frame",nil,left)
distBox:SetPoint("TOPLEFT",distHdr,"BOTTOMLEFT",0,-8)
distBox:SetPoint("TOPRIGHT",left,"TOPRIGHT",-10,0)
distBox:SetHeight(132)

local distLevel=W:Slider(distBox,"|cff7fd6e8Distribution Level|r",2,80,1,260,function(v)
  local db=Log:GetDB()
  if not db then return end
  local x=math.floor((tonumber(v or 2) or 2)+0.5)
  if x<2 then x=2 elseif x>80 then x=80 end
  db.qdistSel=x
  Page:UpdateSummary()
end,function(v)
  return tostring(math.floor((tonumber(v or 2) or 2)+0.5))
end)
distLevel:SetPoint("TOPLEFT",distBox,"TOPLEFT",0,0)
local distBaseY=48
local distVals={}
for q=0,4 do
  local y=q*16
  local l=W:Label(distBox,"",12)
  l:SetPoint("TOPLEFT",distBox,"TOPLEFT",0,-(distBaseY+y))
  local v=W:Label(distBox,"",12)
  v:SetPoint("TOPRIGHT",distBox,"TOPRIGHT",0,-(distBaseY+y))
  v:SetJustifyH("RIGHT")
  distVals[q]={l=l,v=v}
end
local hiHdr=W:Label(left,"Highlights",13)
hiHdr:SetPoint("TOPLEFT",distBox,"BOTTOMLEFT",0,-16)
local hiBox=CreateFrame("Frame",nil,left)
hiBox:SetPoint("TOPLEFT",hiHdr,"BOTTOMLEFT",0,-8)
hiBox:SetPoint("TOPRIGHT",left,"TOPRIGHT",-10,0)
hiBox:SetHeight(70)
local function makeHighlightLine(y,label)
  local l=W:Label(hiBox,"|cff7fd6e8"..label.."|r",12)
  l:SetPoint("TOPLEFT",hiBox,"TOPLEFT",0,-y)
  local b=CreateFrame("Button",nil,hiBox)
  b:SetPoint("LEFT",l,"RIGHT",6,0)
  b:SetHeight(16)
  b:SetWidth(160)
  b:EnableMouse(true)
  local fs=T:Font(b,12,"")
  fs:SetPoint("LEFT",b,"LEFT",0,0)
  b._fs=fs
  local c=W:Label(hiBox,"",12)
  c:SetPoint("TOPRIGHT",hiBox,"TOPRIGHT",0,-y)
  c:SetJustifyH("RIGHT")
  return b,c
end
local bMostPicked,cMostPicked=makeHighlightLine(0,"Most Picked:")
local bMostBan,cMostBan=makeHighlightLine(16,"Most Banished:")
local bLeastSeen,cLeastSeen=makeHighlightLine(32,"Least Seen:")
local shHdr=W:Label(left,"Session Highlights",13)
shHdr:SetPoint("TOPLEFT",hiBox,"BOTTOMLEFT",0,-9)
local shBox=CreateFrame("Frame",nil,left)
shBox:SetPoint("TOPLEFT",shHdr,"BOTTOMLEFT",0,-8)
shBox:SetPoint("TOPRIGHT",left,"TOPRIGHT",-10,0)
shBox:SetHeight(64)
local function addSH(y,label)
  local l=W:Label(shBox,"|cff7fd6e8"..label.."|r",12)
  l:SetPoint("TOPLEFT",shBox,"TOPLEFT",0,-y)
  local v=W:Label(shBox,"",12)
  v:SetPoint("TOPRIGHT",shBox,"TOPRIGHT",0,-y)
  v:SetJustifyH("RIGHT")
  return v
end
local vFR=addSH(0,"Average Level for First Rare:")
local vFE=addSH(16,"Average Level for First Epic:")
local vFL=addSH(32,"Average Level for First Legendary:")


do
  local f=CreateFrame("Frame","EchoArchitectLogbookExportFrame",UIParent)
  f:SetPoint("CENTER",UIParent,"CENTER",0,0)
  f:SetWidth(560)
  f:SetHeight(320)
  T:ApplyPanel(f,"panel")
  f:Hide()
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetClampedToScreen(true)
  local drag=CreateFrame("Frame",nil,f)
  drag:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
  drag:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
  drag:SetHeight(28)
  drag:EnableMouse(true)
  drag:SetScript("OnMouseDown",function() f:StartMoving() end)
  drag:SetScript("OnMouseUp",function() f:StopMovingOrSizing() end)
  drag:SetFrameLevel(f:GetFrameLevel()+1)
  local title=W:Label(f,"Logbook Export",14)
  title:SetPoint("TOPLEFT",f,"TOPLEFT",12,-10)
  local close=W:Button(f,"Close",80,20,function() f:Hide() end)
  close:SetFrameLevel(drag:GetFrameLevel()+5)
  close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-10,-10)
  local help=W:Label(f,"|cFFFF0000WARNING:|r |cFFFFFF00Export / Import can cause lag|r - |cFFFF0000DO NOT CLOSE YOUR GAME|r - |cFF00FF00JUST WAIT|r",12)
  help:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-10)
  local box,eb=W:MultiLineEditBox(f,536,232)
  box:SetPoint("TOPLEFT",help,"BOTTOMLEFT",0,-10)
  local last=""
  eb:SetScript("OnChar",function() end)
  eb:SetScript("OnTextChanged",function(self,user)
    if user then
      self:SetText(last)
      self:HighlightText()
    end
  end)
  local copy=W:Button(f,"Select All",90,20,function() eb:SetFocus() eb:HighlightText() end)
  copy:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",12,12)
  local refresh=W:Button(f,"Refresh",90,20,function() if f.ShowExport then f:ShowExport() end end)
  refresh:SetPoint("LEFT",copy,"RIGHT",10,0)
  function f:ShowExport()
    local payload=(EA.Logbook and EA.Logbook.BuildExport and EA.Logbook:BuildExport()) or {}
    local s=(EA.Serialize and EA.Serialize.Export and EA.Serialize:Export(payload)) or ""
    last=s
    eb:SetMaxLetters(strlen(s))
    eb:SetText(s)
    eb:SetFocus()
    eb:HighlightText()
    self:Show()
  end
  Page._export=f
end

do
  local f=CreateFrame("Frame","EchoArchitectLogbookImportFrame",UIParent)
  f:SetPoint("CENTER",UIParent,"CENTER",0,0)
  f:SetWidth(560)
  f:SetHeight(360)
  T:ApplyPanel(f,"panel")
  f:Hide()
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetClampedToScreen(true)
  local drag=CreateFrame("Frame",nil,f)
  drag:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
  drag:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
  drag:SetHeight(28)
  drag:EnableMouse(true)
  drag:SetScript("OnMouseDown",function() f:StartMoving() end)
  drag:SetScript("OnMouseUp",function() f:StopMovingOrSizing() end)
  drag:SetFrameLevel(f:GetFrameLevel()+1)
  local title=W:Label(f,"Logbook Import",14)
  title:SetPoint("TOPLEFT",f,"TOPLEFT",12,-10)
  local close=W:Button(f,"Close",80,20,function() f:Hide() end)
  close:SetFrameLevel(drag:GetFrameLevel()+5)
  close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-10,-10)
  local help=W:Label(f,"|cFFFF0000WARNING:|r |cFFFFFF00Export / Import can cause lag|r - |cFFFF0000DO NOT CLOSE YOUR GAME|r - |cFF00FF00JUST WAIT|r",12)
  help:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-10)
  local status=W:Label(f,"",12)
  status:SetPoint("TOPLEFT",help,"BOTTOMLEFT",0,-8)
  local box,eb=W:MultiLineEditBox(f,536,220)
  box:SetPoint("TOPLEFT",status,"BOTTOMLEFT",0,-10)
  local paste=W:Button(f,"Select All",90,20,function() eb:SetFocus() eb:HighlightText() end)
  paste:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",12,12)
  local clear=W:Button(f,"Clear",90,20,function() eb:SetText("") status:SetText("") end)
  clear:SetPoint("LEFT",paste,"RIGHT",10,0)
  local importBtn=W:Button(f,"Import & Merge",130,20,function()
    local s=tostring(eb:GetText() or "")
    local payload,err=(EA.Serialize and EA.Serialize.Import and EA.Serialize:Import(s))
    if not payload then
      status:SetText("|cffff7777Import failed: "..tostring(err or "unknown").."|r")
      return
    end
    local ok,res=(EA.Logbook and EA.Logbook.ImportExport and EA.Logbook:ImportExport(payload))
    if not ok then
      status:SetText("|cffff7777Import failed: "..tostring(res or "unknown").."|r")
      return
    end
    local me=type(res)=="table" and tonumber(res.mergedEcho or 0) or 0
    local mq=type(res)=="table" and tonumber(res.mergedQDist or 0) or 0
    status:SetText("|cff77ff77Merged. Echo entries: "..tostring(me).."  QDist adds: "..tostring(mq).."|r")
    Page:UpdateSummary()
    Page:UpdateList()
  end)
  importBtn:SetPoint("LEFT",clear,"RIGHT",10,0)
  function f:ShowImport()
    status:SetText("")
    eb:SetFocus()
    self:Show()
  end
  Page._import=f
end

local searchLabel=W:Label(right,"Search",12)
searchLabel:SetPoint("TOPLEFT",right,"TOPLEFT",10,-10)
local searchBox=W:EditBox(right,190,20)
searchBox:SetPoint("LEFT",searchLabel,"RIGHT",8,0)
local searchModeBtn
searchModeBtn=W:Button(right,"Search: Name+Rarity",140,20,function()
  local s=sortState()
  s.searchMode=(s.searchMode=="tooltip") and "name" or "tooltip"
  if s.searchMode=="tooltip" then searchModeBtn:SetText("Search: Tooltip") else searchModeBtn:SetText("Search: Name+Rarity") end
  Page:UpdateList()
end)
searchModeBtn:SetPoint("LEFT",searchBox,"RIGHT",10,0)
local ss=sortState()
if ss.searchMode=="tooltip" then searchModeBtn:SetText("Search: Tooltip") else searchModeBtn:SetText("Search: Name+Rarity") end
local exportBtn=W:Button(right,"Export",80,20,function()
  if Page._export and Page._export.ShowExport then Page._export:ShowExport() end
end)
exportBtn:SetPoint("TOPRIGHT",right,"TOPRIGHT",-10,-10)
local importBtn=W:Button(right,"Import",80,20,function()
  if Page._import and Page._import.ShowImport then Page._import:ShowImport() end
end)
importBtn:SetPoint("RIGHT",exportBtn,"LEFT",0,0)
local header=CreateFrame("Frame",nil,right)
header:SetPoint("TOPLEFT",searchLabel,"BOTTOMLEFT",0,-10)
header:SetPoint("TOPRIGHT",right,"TOPRIGHT",-10,0)
header:SetHeight(20)
local COL_ICON=16
local COL_GAP=6
local COL_NAME=200
local COL_QUAL=92
local COL_SEEN=60
local COL_BAN=70
local COL_PICK=60
local x0=COL_ICON+COL_GAP
local setOff
function Page:ToggleSort(k)
  local s=sortState()
  if s.sortKey==k then s.sortAsc=not s.sortAsc else s.sortKey=k s.sortAsc=true end
  setOff(0)
  self:UpdateList()
end
local hName=W:Button(header,"Name",COL_NAME,18,function() Page:ToggleSort("name") end)
hName:SetPoint("LEFT",header,"LEFT",x0,0)
local hQual=W:Button(header,"Quality",COL_QUAL,18,function() Page:ToggleSort("quality") end)
hQual:SetPoint("LEFT",hName,"RIGHT",8,0)
local hSeen=W:Button(header,"Seen",COL_SEEN,18,function() Page:ToggleSort("seen") end)
hSeen:SetPoint("LEFT",hQual,"RIGHT",16,0)
local hBan=W:Button(header,"Banished",COL_BAN,18,function() Page:ToggleSort("banished") end)
hBan:SetPoint("LEFT",hSeen,"RIGHT",16,0)
local hPick=W:Button(header,"Picked",COL_PICK,18,function() Page:ToggleSort("picked") end)
hPick:SetPoint("LEFT",hBan,"RIGHT",16,0)
local list=CreateFrame("Frame",nil,right)
list:SetPoint("TOPLEFT",header,"BOTTOMLEFT",0,-6)
list:SetPoint("BOTTOMLEFT",right,"BOTTOMLEFT",10,10)
list:SetPoint("TOPRIGHT",right,"TOPRIGHT",-36,-68)
list:SetPoint("BOTTOMRIGHT",right,"BOTTOMRIGHT",-36,10)
local colSep=CreateFrame("Frame",nil,right)
colSep:SetPoint("TOPLEFT",header,"TOPLEFT",0,0)
colSep:SetPoint("BOTTOMRIGHT",list,"BOTTOMRIGHT",0,0)
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
local _seps={vline(0),vline(0),vline(0),vline(0)}
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
  setLine(_seps[1],mid(hName,hQual))
  setLine(_seps[2],mid(hQual,hSeen))
  setLine(_seps[3],mid(hSeen,hBan))
  setLine(_seps[4],mid(hBan,hPick))
end
local scroll=CreateFrame("ScrollFrame","EchoArchitectLogbookScroll",right,"FauxScrollFrameTemplate")
scroll:ClearAllPoints()
scroll:SetPoint("TOP",list,"TOP",0,0)
scroll:SetPoint("BOTTOM",list,"BOTTOM",0,0)
scroll:SetPoint("LEFT",list,"RIGHT",8,0)
scroll:SetPoint("RIGHT",right,"RIGHT",-10,0)
scroll:SetScript("OnVerticalScroll",function(self,offset)
  FauxScrollFrame_OnVerticalScroll(self,offset,20,function() Page:UpdateList() end)
end)
local sb=_G[scroll:GetName().."ScrollBar"]
if sb then
  sb:ClearAllPoints()
  sb:SetPoint("TOPLEFT",scroll,"TOPLEFT",7,0)
  sb:SetPoint("BOTTOMLEFT",scroll,"BOTTOMLEFT",7,0)
  T:ApplyScrollBar(sb)
  sb:Show()
end
setOff=function(v)
  v=tonumber(v or 0) or 0
  scroll.offset=v
  if sb and sb.SetValue then sb:SetValue(v*20) end
end
list:EnableMouseWheel(true)
list:SetScript("OnMouseWheel",function(_,delta)
  if not sb or not sb.GetValue or not sb.SetValue then return end
  local v=tonumber(sb:GetValue() or 0) or 0
  sb:SetValue(v-(delta*20*3))
end)
local rows={}
local rowH=20
local ROWS=22
for i=1,ROWS do
  local r=CreateFrame("Frame",nil,list)
  r:SetHeight(rowH)
  r:SetPoint("TOPLEFT",list,"TOPLEFT",0,-(i-1)*rowH)
  r:SetPoint("TOPRIGHT",list,"TOPRIGHT",0,-(i-1)*rowH)
  local icon=r:CreateTexture(nil,"ARTWORK")
  icon:SetWidth(16)
  icon:SetHeight(16)
  icon:SetPoint("LEFT",r,"LEFT",0,0)
  local nameBtn=W:Button(r,"",COL_NAME,18,function() end)
  nameBtn:SetPoint("LEFT",icon,"RIGHT",COL_GAP,0)
  local qual=W:BoxButton(r,"",COL_QUAL,18)
  qual:SetPoint("LEFT",nameBtn,"RIGHT",8,0)
  qual._fs:SetJustifyH("CENTER")
  local seen=W:BoxButton(r,"",COL_SEEN,18)
  seen:SetPoint("LEFT",qual,"RIGHT",16,0)
  seen._fs:SetJustifyH("CENTER")
  local ban=W:BoxButton(r,"",COL_BAN,18)
  ban:SetPoint("LEFT",seen,"RIGHT",16,0)
  ban._fs:SetJustifyH("CENTER")
  local pick=W:BoxButton(r,"",COL_PICK,18)
  pick:SetPoint("LEFT",ban,"RIGHT",16,0)
  pick._fs:SetJustifyH("CENTER")
  r._icon=icon
  r._nameBtn=nameBtn
  r._name=nameBtn._fs
  r._qual=qual
  r._seen=seen
  r._ban=ban
  r._pick=pick
  rows[i]=r
end
local function keyParts(key)
  local sid=tonumber(string.match(key,"^(%d+):") or 0) or 0
  local q=tonumber(string.match(key,":(%d+)$") or 0) or 0
  return sid,q
end
local function getList()
  local db=Log:GetDB()
  local out={}
  local s=sortState()
  local q=(searchBox:GetText() or "")
  q=string.lower(q)
  local mode=s.searchMode or "name"
  for key,v in pairs(db.perEcho or {}) do
    local sid,qual=keyParts(key)
    local nm=(GetSpellInfo and GetSpellInfo(sid)) or tostring(sid)
    local plain=string.lower(nm)
    local ok=false
    if q=="" then ok=true
    elseif mode=="tooltip" then
      local tip=W:GetSpellTooltipText(sid)
      if tip~="" and string.find(tip,q,1,true) then ok=true end
    else
      if string.find(plain,q,1,true) then ok=true end
      local qn=string.lower(QualityName(tonumber(v.quality or qual or 0) or 0) or "")
      if (not ok) and qn~="" and string.find(qn,q,1,true) then ok=true end
    end
    if ok then
      out[#out+1]={
        key=key,
        sid=sid,
        quality=tonumber(v.quality or qual or 0) or 0,
        seen=tonumber(v.seen or 0) or 0,
        banished=tonumber(v.banished or 0) or 0,
        picked=tonumber(v.picked or 0) or 0,
        name=nm,
      }
    end
  end
  local s=sortState()
  local k=s.sortKey
  local asc=s.sortAsc
  table.sort(out,function(a,b)
  if a==b then return false end
  if not a then return false end
  if not b then return true end
  local function nrm(x) return string.lower(tostring(x or "")) end
  local an=nrm(a.name)
  local bn=nrm(b.name)
  local function cmp(av,bv,isAsc)
    if av==bv then return nil end
    if isAsc then return av<bv end
    return av>bv
  end
  local k=s.sortKey
  local isAsc=s.sortAsc
  local av,bv,res
  if k=="quality" then
    av=tonumber(a.quality or 0) or 0
    bv=tonumber(b.quality or 0) or 0
    res=cmp(av,bv,isAsc)
    if res~=nil then return res end
    res=cmp(an,bn,true)
    if res~=nil then return res end
    return tostring(a.key or "")<tostring(b.key or "")
  elseif k=="picked" then av=tonumber(a.picked or 0) or 0 bv=tonumber(b.picked or 0) or 0
  elseif k=="banished" then av=tonumber(a.banished or 0) or 0 bv=tonumber(b.banished or 0) or 0
  elseif k=="seen" then av=tonumber(a.seen or 0) or 0 bv=tonumber(b.seen or 0) or 0
  else
    res=cmp(an,bn,isAsc)
    if res~=nil then return res end
    av=tonumber(a.quality or 0) or 0
    bv=tonumber(b.quality or 0) or 0
    res=cmp(av,bv,isAsc)
    if res~=nil then return res end
    return tostring(a.key or "")<tostring(b.key or "")
  end
  res=cmp(av,bv,isAsc)
  if res~=nil then return res end
  res=cmp(an,bn,true)
  if res~=nil then return res end
  av=tonumber(a.quality or 0) or 0
  bv=tonumber(b.quality or 0) or 0
  res=cmp(av,bv,true)
  if res~=nil then return res end
  return tostring(a.key or "")<tostring(b.key or "")
end)

  return out
end

local function resolveIcon(sid)
  sid=tonumber(sid or 0) or 0
  if sid<=0 then return "Interface\\Icons\\INV_Misc_QuestionMark" end
  local ic=nil
  if type(GetSpellTexture)=="function" then ic=GetSpellTexture(sid) end
  if not ic and type(GetSpellInfo)=="function" then
    local _,_,t=GetSpellInfo(sid)
    ic=t
  end
  if not ic and GameTooltip and GameTooltip.SetOwner and GameTooltip.SetHyperlink then
    GameTooltip:SetOwner(UIParent,"ANCHOR_NONE")
    GameTooltip:SetHyperlink("spell:"..tostring(sid))
    GameTooltip:Hide()
    if type(GetSpellTexture)=="function" then ic=GetSpellTexture(sid) end
    if not ic and type(GetSpellInfo)=="function" then
      local _,_,t=GetSpellInfo(sid)
      ic=t
    end
  end
  return ic or "Interface\\Icons\\INV_Misc_QuestionMark"
end
local function setHighlight(btn,key)
  if not key then
    btn._fs:SetText("|cffaaaaaaNone|r")
    btn:SetScript("OnEnter",nil)
    btn:SetScript("OnLeave",nil)
    return
  end
  local sid,q=keyParts(key)
  local col=DB:QualityColor(q)
  local nm=(GetSpellInfo and GetSpellInfo(sid)) or tostring(sid)
  btn._fs:SetText(col..nm.."|r")
  W:AttachSpellTooltip(btn,function() return sid end)
end
function Page:UpdateSummary()
  local db=Log:GetDB()
  local t=db.totals
  vSeen:SetText(t.echoesSeen or 0)
  vRuns:SetText(t.runsCompleted or 0)
  vPicks:SetText(t.picks or 0)
  vRerolls:SetText(t.rerolls or 0)
  vBanishes:SetText(t.banishes or 0)
  local spm=EA.Run and EA.Run.ShadowstepsPerMinute and EA.Run:ShadowstepsPerMinute() or 0
  if spm>0 then vSSPM:SetText(string.format("%.2f",spm)) else vSSPM:SetText("0") end
	  local sel=tonumber(db.qdistSel or 2) or 2
	  if sel<2 then sel=2 elseif sel>80 then sel=80 end
	  if distLevel and distLevel.SetValue then distLevel:SetValue(sel) end
	  local seenByQ,totalS=Log:ComputeSeenByQualityAtEchoLevel(sel)
  for q=0,4 do
    local col=DB:QualityColor(q)
    distVals[q].l:SetText(col..qLabel(q).."|r:")
    distVals[q].v:SetText("("..tostring(seenByQ[q] or 0)..") "..pct(seenByQ[q] or 0,totalS))
  end
  local mostPickedKey,mp=Log:TopEchoBy("picked")
  local mostBanKey,mb=Log:TopEchoBy("banished")
  local leastSeenKey,ls=Log:LeastSeenAvailable()
  setHighlight(bMostPicked,mostPickedKey)
  cMostPicked:SetText("("..tostring(mp or 0)..")")
  setHighlight(bMostBan,mostBanKey)
  cMostBan:SetText("("..tostring(mb or 0)..")")
  setHighlight(bLeastSeen,leastSeenKey)
  cLeastSeen:SetText("("..tostring(ls or 0)..")")
  local sh=db.sessionHighlights or {}
  local f=sh.first or {}
  local function avg(t)
    if type(t)~="table" then return nil end
    local c=tonumber(t.count or 0) or 0
    if c<=0 then return nil end
    return (tonumber(t.sum or 0) or 0)/c
  end
  local ar=avg(f.rare)
  local ae=avg(f.epic)
  local al=avg(f.legendary)
  vFR:SetText(ar and string.format("%.1f",ar) or "Never")
  vFE:SetText(ae and string.format("%.1f",ae) or "Never")
  vFL:SetText(al and string.format("%.1f",al) or "Never")

end
function Page:UpdateList()
  local data=getList()
  local total=#data
  FauxScrollFrame_Update(scroll,total,ROWS,rowH)
  local off=FauxScrollFrame_GetOffset(scroll)
  for i=1,ROWS do
    local idx=i+off
    local r=rows[i]
    local d=data[idx]
    if d then
      r:Show()
      local col=DB:QualityColor(d.quality)
      r._name:SetText(col..d.name.."|r")
      r._qual:SetText(col..qLabel(d.quality).."|r")
      r._seen:SetText(tostring(d.seen))
      r._ban:SetText(tostring(d.banished))
      r._pick:SetText(tostring(d.picked))
      local ic=resolveIcon(d.sid)
      r._icon:SetTexture(ic)
      r._icon:SetVertexColor(1,1,1,1)
      W:AttachSpellTooltip(r._nameBtn,function() return d.sid end)
    else
      r:Hide()
    end
  end
end
local function refresh()
  Page:UpdateSummary()
  Page:UpdateList()
end
searchBox:SetScript("OnTextChanged",function() setOff(0) Page:UpdateList() end)
Page:SetScript("OnSizeChanged",function() _UpdateSeps() end)
Page:SetScript("OnShow",function()
  _UpdateSeps()
  setOff(0)
  refresh()
end)
Win:RegisterPage("logbook",Page)
