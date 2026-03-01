local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
local UI=EA.UI
local Win=UI.Window
local W=UI.Widgets
local T=UI.Theme
local DB=EA.DB
local Log=EA.Logbook
local searchModeBtn
local Page=CreateFrame("Frame",nil,UIParent)
T:ApplyPanel(Page,"bg")
local GAP=4
local ICON_PAD=4
local ICON_W=18
local ICON_GAP=6
local START_X=ICON_PAD+ICON_W+ICON_GAP
local LIST_RIGHT_INSET=26
local NAME_W=170
local BUCKET_W=106
local QUALITY_W=100
local WEIGHT_W=60
local BLACKLIST_W=60
local BSTACKS_W=60
local BNAME_W=170
local SEP1=START_X+NAME_W+(GAP/2)
local SEP2=SEP1+(GAP/2)+GAP+BUCKET_W
local SEP3=SEP2+(GAP/2)+GAP+QUALITY_W
local SEP4=SEP3+(GAP/2)+GAP+WEIGHT_W
local B_ICON_W=18
local B_START_X=ICON_PAD+B_ICON_W+ICON_GAP
local BSEP1=B_START_X+BNAME_W+(GAP/2)
local BSEP2=BSEP1+(GAP/2)+GAP+BSTACKS_W
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
local lSearch=W:Label(left,"Search",12)
lSearch:SetPoint("TOPLEFT",left,"TOPLEFT",10,-10)
local eSearch=W:EditBox(left,220,20)
eSearch:SetPoint("LEFT",lSearch,"RIGHT",8,0)
searchModeBtn=W:Button(left,"Search: Name+Rarity",140,20,function()
  local db=EchoArchitect_CharDB
  db.ui=db.ui or {}
  db.ui.library=db.ui.library or {}
  db.ui.library.searchMode=(db.ui.library.searchMode=="tooltip") and "name" or "tooltip"
  if db.ui.library.searchMode=="tooltip" then searchModeBtn:SetText("Search: Tooltip") else searchModeBtn:SetText("Search: Name+Rarity") end
  Page:UpdateList(true)
end)
searchModeBtn:SetPoint("LEFT",eSearch,"RIGHT",10,0)
local chkAll=W:Check(left,"All Echoes",function(_,v)
  local db=EchoArchitect_CharDB
  if db and db.ui and db.ui.library then db.ui.library.showAll=v end
  Page:UpdateList(true)
  Page:UpdateBucketPanel()
end)
chkAll:SetPoint("LEFT",searchModeBtn,"RIGHT",10,0)
local headers=CreateFrame("Frame",nil,left)
headers:SetPoint("TOPLEFT",lSearch,"BOTTOMLEFT",0,-12)
headers:SetPoint("TOPRIGHT",left,"TOPRIGHT",-LIST_RIGHT_INSET,-12)
headers:SetHeight(18)
local hName=W:Button(headers,"Name",NAME_W,18,function() Page:ToggleSort("name") end)
hName:SetPoint("LEFT",headers,"LEFT",START_X,0)
local hBucket=W:Button(headers,"Bucket",BUCKET_W,18,function() Page:ToggleSort("bucket") end)
  local hQ=W:Button(headers,"Quality",QUALITY_W,18,function() Page:ToggleSort("quality") end)
  local hW=W:Button(headers,"Weight",WEIGHT_W,18,function() Page:ToggleSort("weight") end)
  local hB=W:Button(headers,"Blacklist",BLACKLIST_W,18,function() Page:ToggleSort("blacklist") end)
  hB:ClearAllPoints()
  hB:SetPoint("RIGHT",headers,"RIGHT",-4,0)
  hW:ClearAllPoints()
  hW:SetPoint("RIGHT",hB,"LEFT",-GAP,0)
  hQ:ClearAllPoints()
  hQ:SetPoint("RIGHT",hW,"LEFT",-GAP,0)
  hBucket:ClearAllPoints()
  hBucket:SetPoint("RIGHT",hQ,"LEFT",-GAP,0)
  hBucket:SetPoint("LEFT",hName,"RIGHT",GAP,0)
local list=CreateFrame("Frame",nil,left)
list:SetPoint("TOPLEFT",headers,"BOTTOMLEFT",0,-8)
list:SetPoint("BOTTOMLEFT",left,"BOTTOMLEFT",0,10)
list:SetPoint("BOTTOMRIGHT",left,"BOTTOMRIGHT",-LIST_RIGHT_INSET,10)
local colSep=CreateFrame("Frame",nil,left)
colSep:SetPoint("TOPLEFT",headers,"TOPLEFT",0,0)
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
local _seps={vline(SEP1),vline(SEP2),vline(SEP3),vline(SEP4)}
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
  setLine(_seps[1],mid(hName,hBucket))
  setLine(_seps[2],mid(hBucket,hQ))
  setLine(_seps[3],mid(hQ,hW))
  setLine(_seps[4],mid(hW,hB))
end
local scroll=CreateFrame("ScrollFrame","EchoArchitectLibraryScroll",left,"FauxScrollFrameTemplate")
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
local rows={}
local ROWS=17
local function QualityName(q)
  if q==0 then return "Common" end
  if q==1 then return "Uncommon" end
  if q==2 then return "Rare" end
  if q==3 then return "Epic" end
  if q==4 then return "Legendary" end
  return "Unknown"
end
local function ucfirst(s)
  if not s then return "" end
  return string.upper(string.sub(s,1,1))..string.lower(string.sub(s,2))
end
local bucketTooltip
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
for i=1,ROWS do
  local r=CreateFrame("Frame",nil,list)
  r:SetHeight(24)
  r:SetPoint("TOPLEFT",list,"TOPLEFT",0,-(i-1)*26)
  r:SetPoint("TOPRIGHT",list,"TOPRIGHT",0,-(i-1)*26)
  local bg=r:CreateTexture(nil,"BACKGROUND")
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetPoint("TOPLEFT",r,"TOPLEFT",0,0)
  bg:SetPoint("BOTTOMRIGHT",r,"BOTTOMRIGHT",0,0)
  bg:SetVertexColor(0,0,0,0)
  local icon=r:CreateTexture(nil,"ARTWORK")
  icon:SetWidth(18) icon:SetHeight(18)
  icon:SetPoint("LEFT",r,"LEFT",4,0)
  local nameBtn=W:Button(r,"",NAME_W,20,function() end)
  nameBtn:SetPoint("LEFT",icon,"RIGHT",6,0)
  local bucketBtn=W:Button(r,"None",BUCKET_W,20,function() if r._entry then Page:ShowBucketMenu(bucketBtn,r._entry.key) end end)
  bucketBtn:SetPoint("LEFT",nameBtn,"RIGHT",4,0)
  local qBox=W:BoxButton(r,"",QUALITY_W,20)
  qBox._fs:SetJustifyH("CENTER")
  local wBox=W:EditBox(r,WEIGHT_W,20)
  wBox:SetJustifyH("CENTER")
  local blkBox=CreateFrame("Frame",nil,r)
  blkBox:SetSize(BLACKLIST_W,20)
  blkBox:ClearAllPoints()
  blkBox:SetPoint("RIGHT",r,"RIGHT",-4,0)
  wBox:ClearAllPoints()
  wBox:SetPoint("RIGHT",blkBox,"LEFT",-GAP,0)
  qBox:ClearAllPoints()
  qBox:SetPoint("RIGHT",wBox,"LEFT",-GAP,0)
  bucketBtn:ClearAllPoints()
  bucketBtn:SetPoint("RIGHT",qBox,"LEFT",-GAP,0)
  bucketBtn:SetPoint("LEFT",nameBtn,"RIGHT",GAP,0)
  bg:ClearAllPoints()
  bg:SetPoint("TOPLEFT",r,"TOPLEFT",0,0)
  bg:SetPoint("BOTTOMRIGHT",r,"BOTTOMRIGHT",0,0)
  local blk=W:Check(r,"",function(_,v)
    if r._key then
      local p=EA.Profiles:GetActiveProfile()
      p.blacklist[r._key]=v and true or nil
      Page:UpdateRow(r)
    end
  end)
  blk:SetWidth(20)
  blk:SetPoint("CENTER",blkBox,"CENTER",0,0)
  local blkHit=CreateFrame("Button",nil,r)
  blkHit:SetAllPoints(blkBox)
  blkHit:SetScript("OnClick",function() blk._btn:Click() end)
  r._bg=bg
  r._icon=icon
  r._nameBtn=nameBtn
  r._qBox=qBox
  r._wBox=wBox
  r._bucketBtn=bucketBtn
  r._blk=blk
  rows[i]=r
end
local inspectorFrame=CreateFrame("Frame",nil,right)
inspectorFrame:SetPoint("TOPLEFT",right,"TOPLEFT",10,-10)
inspectorFrame:SetPoint("TOPRIGHT",right,"TOPRIGHT",-10,-10)
inspectorFrame:SetHeight(150)
local ibg=inspectorFrame:CreateTexture(nil,"BACKGROUND")
ibg:SetAllPoints(inspectorFrame)
ibg:SetTexture("Interface\\Buttons\\WHITE8X8")
ibg:SetVertexColor(0.04,0.06,0.10,0.40)
local inspectorTitle=W:Label(inspectorFrame,"",16)
local insTop=CreateFrame("Frame",nil,inspectorFrame)
insTop:SetPoint("TOPLEFT",inspectorFrame,"TOPLEFT",8,-10)
insTop:SetPoint("TOPRIGHT",inspectorFrame,"TOPRIGHT",-8,-10)
insTop:SetHeight(40)
insTop:Hide()
local insIcon=insTop:CreateTexture(nil,"ARTWORK")
insIcon:SetWidth(1) insIcon:SetHeight(1)
insIcon:SetPoint("LEFT",insTop,"LEFT",0,0)
insIcon:SetAlpha(0)
local insName=T:Font(insTop,16,"")
insName:SetPoint("TOPLEFT",insTop,"TOPLEFT",0,0)

insName:SetPoint("TOPRIGHT",insTop,"TOPRIGHT",0,-2)
insName:SetJustifyH("LEFT")
insName:SetAlpha(0)
local insSub=T:Font(insTop,12,"")
insSub:SetPoint("TOPLEFT",insName,"BOTTOMLEFT",0,-6)
insSub:SetPoint("TOPRIGHT",insTop,"TOPRIGHT",0,-6)
insSub:SetJustifyH("LEFT")
insSub:SetAlpha(0)
local insInfo=CreateFrame("Frame",nil,inspectorFrame)
insInfo:SetPoint("TOPLEFT",inspectorFrame,"TOPLEFT",8,-10)
insInfo:SetPoint("TOPRIGHT",inspectorFrame,"TOPRIGHT",-8,-10)
insInfo:SetPoint("BOTTOMLEFT",inspectorFrame,"BOTTOMLEFT",8,16)
local function makeField(y,label)
  local l=T:Font(insInfo,12,"")
  l:SetPoint("TOPLEFT",insInfo,"TOPLEFT",0,y)
  l:SetJustifyH("LEFT")
  l:SetText(label)
  local v=T:Font(insInfo,12,"")
  v:SetPoint("LEFT",l,"RIGHT",8,0)
  v:SetPoint("RIGHT",insInfo,"RIGHT",0,0)
  v:SetJustifyH("LEFT")
  return v
end
local vShown=T:Font(insInfo,12,"")
vShown:SetPoint("TOPLEFT",insInfo,"TOPLEFT",0,0)
vShown:SetJustifyH("LEFT")
vShown:SetText("Echoes Shown: 0 (0)")
local vSpell=makeField(-18,"Spell ID:")
local vQuality=makeField(-36,"Quality:")
local bL=T:Font(insInfo,12,"")
bL:SetPoint("TOPLEFT",insInfo,"TOPLEFT",0,-54)
bL:SetJustifyH("LEFT")
bL:SetText("Bucket:")
local bIcon=insInfo:CreateTexture(nil,"ARTWORK")
bIcon:SetWidth(14) bIcon:SetHeight(14)
bIcon:SetPoint("LEFT",bL,"RIGHT",8,0)
bIcon:SetTexture("Interface\\Icons\\inv_misc_1h_bucket_c_01")
local vBucketBtn=CreateFrame("Button",nil,insInfo)
vBucketBtn:SetPoint("LEFT",bIcon,"RIGHT",4,0)
vBucketBtn:SetWidth(BUCKET_W)
vBucketBtn:SetHeight(14)
vBucketBtn:EnableMouse(true)
vBucketBtn._fs=T:Font(vBucketBtn,12,"")
vBucketBtn._fs:SetPoint("LEFT",vBucketBtn,"LEFT",0,0)
local vStacks=makeField(-72,"Max Stacks:")
local rL=T:Font(insInfo,12,"")
rL:SetPoint("TOPLEFT",insInfo,"TOPLEFT",0,-90)
rL:SetJustifyH("LEFT")
rL:SetText("Unlock:")
local rIcon=insInfo:CreateTexture(nil,"ARTWORK")
rIcon:SetWidth(14) rIcon:SetHeight(14)
rIcon:SetPoint("LEFT",rL,"RIGHT",8,0)
rIcon:SetTexture("Interface\\Buttons\\WHITE8X8")
rIcon:SetVertexColor(0,0,0,0)
local vReqBtn=CreateFrame("Button",nil,insInfo)
vReqBtn:SetPoint("LEFT",rIcon,"RIGHT",4,0)
vReqBtn:SetWidth(BUCKET_W)
vReqBtn:SetHeight(14)
vReqBtn:EnableMouse(true)
vReqBtn._fs=T:Font(vReqBtn,12,"")
vReqBtn._fs:SetPoint("LEFT",vReqBtn,"LEFT",0,0)
local clsLabel=T:Font(insInfo,12,"")
clsLabel:SetPoint("TOPLEFT",insInfo,"TOPLEFT",0,-108)
clsLabel:SetJustifyH("LEFT")
clsLabel:SetText("Classes:")
local clsFrame=CreateFrame("Frame",nil,insInfo)
clsFrame:SetPoint("TOPLEFT",clsLabel,"BOTTOMLEFT",0,-6)
clsFrame:SetPoint("TOPRIGHT",insInfo,"TOPRIGHT",0,-114)
clsFrame:SetHeight(18)
local classOrder={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","DRUID"}
local classBits={WARRIOR=1,PALADIN=2,HUNTER=4,ROGUE=8,PRIEST=16,DEATHKNIGHT=32,SHAMAN=64,MAGE=128,WARLOCK=256,DRUID=1024}
local clsIcons={}
for i=1,#classOrder do
  local f=CreateFrame("Frame",nil,clsFrame)
  f:SetSize(18,18)
  if i==1 then f:SetPoint("LEFT",clsFrame,"LEFT",0,0) else f:SetPoint("LEFT",clsIcons[i-1],"RIGHT",3,0) end
  local tx=f:CreateTexture(nil,"ARTWORK")
  tx:SetAllPoints()
  tx:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
  local c=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classOrder[i]]
  if c then tx:SetTexCoord(c[1],c[2],c[3],c[4]) else tx:SetTexCoord(0,1,0,1) end
  f._tex=tx
  f._class=classOrder[i]
  f:EnableMouse(true)
  f:SetScript("OnEnter",function(self)
    if GameTooltip then
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      local lab=self._class
      local pretty=(DB and DB.ClassPrettyName and DB:ClassPrettyName(lab)) or lab
      GameTooltip:SetText(((DB and DB.ClassColorCode and DB:ClassColorCode(lab)) or "|cffffffff")..pretty.."|r",1,1,1,true)
      GameTooltip:Show()
    end
  end)
  f:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  clsIcons[i]=f
end
Page._clsIcons=clsIcons
Page._classBits=classBits
Page._classOrder=classOrder
if vBucketBtn then
  vBucketBtn:SetScript("OnEnter",function(self) if self._bid then bucketTooltip(self,self._bid,"ANCHOR_RIGHT") elseif self._tipText then GameTooltip:SetOwner(self,"ANCHOR_RIGHT") GameTooltip:SetText(self._tipText,1,1,1,true) GameTooltip:Show() end end)
  vBucketBtn:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end
if vReqBtn then
  vReqBtn:SetScript("OnEnter",function(self) if self._sid then ShowSpellTooltip(self,self._sid) elseif self._tipText then GameTooltip:SetOwner(self,"ANCHOR_RIGHT") GameTooltip:SetText(self._tipText,1,1,1,true) GameTooltip:Show() end end)
  vReqBtn:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end
local tipAnchor=CreateFrame("Frame",nil,inspectorFrame)
tipAnchor:SetPoint("TOPLEFT",inspectorFrame,"TOPLEFT",0,0)
tipAnchor:SetPoint("BOTTOMRIGHT",inspectorFrame,"BOTTOMRIGHT",0,0)
local insTip=CreateFrame("GameTooltip","EchoArchitectInspectorTooltip",inspectorFrame,"GameTooltipTemplate")
insTip:ClearAllPoints()
insTip:SetPoint("TOPLEFT",tipAnchor,"TOPLEFT",0,0)
insTip:SetPoint("BOTTOMRIGHT",tipAnchor,"BOTTOMRIGHT",0,0)
insTip:SetScale(0.95)
insTip:SetFrameStrata("TOOLTIP")

local bSettings=CreateFrame("Frame",nil,right)
bSettings:SetPoint("TOPLEFT",inspectorFrame,"BOTTOMLEFT",0,-34)
bSettings:SetPoint("TOPRIGHT",right,"TOPRIGHT",-LIST_RIGHT_INSET,-34)
bSettings:SetHeight(72)
local sbg=bSettings:CreateTexture(nil,"BACKGROUND")
sbg:SetAllPoints(bSettings)
sbg:SetTexture("Interface\\Buttons\\WHITE8X8")
sbg:SetVertexColor(0.04,0.06,0.10,0.40)
local selName=W:Label(bSettings,"",12)
selName:SetAlpha(0)
local newName=W:EditBox(bSettings,220,20)
newName:SetPoint("TOPLEFT",bSettings,"TOPLEFT",8,-10)
local btnCreate=W:Button(bSettings,"Create Bucket",110,20,function()
  local pr=Page:EnsureBuckets()
  if not pr then return end
  local nm=newName:GetText() or ""
  nm=string.gsub(nm,"^%s+","")
  nm=string.gsub(nm,"%s+$","")
  if nm=="" then return end
  local bid="b"..tostring(GetTime())
  pr.buckets[bid]={name=nm,maxStacks=0,echoKeys={}}
  Page._bucketSelId=bid
  newName:SetText("")
  Page:UpdateBucketPanel()
end)
btnCreate:SetPoint("TOPRIGHT",bSettings,"TOPRIGHT",-8,-10)
newName:SetPoint("RIGHT",btnCreate,"LEFT",-8,0)
local bucketHint=T:Font(bSettings,11,"")
bucketHint:SetFont("Fonts\\MORPHEUS.TTF",11,"")
bucketHint:SetJustifyH("CENTER")
bucketHint:SetText("It puts the lotion in the bucket")
bucketHint:SetAlpha(0.65)
bucketHint:SetPoint("TOP",btnCreate,"BOTTOM",0,-6)
bucketHint:SetPoint("LEFT",bSettings,"LEFT",8,0)
bucketHint:SetPoint("RIGHT",bSettings,"RIGHT",-8,0)

local bSearchLbl=W:Label(bSettings,"Search",12)
bSearchLbl:SetPoint("TOPLEFT",bucketHint,"BOTTOMLEFT",0,-6)
local bSearch=W:EditBox(bSettings,220,20)
bSearch:SetPoint("LEFT",bSearchLbl,"RIGHT",8,0)
bSearch:SetPoint("RIGHT",bSettings,"RIGHT",-8,0)
bSearch:SetJustifyH("LEFT")
Page._bucketSearch=bSearch
bSearch:SetScript("OnTextChanged",function() Page:UpdateBucketList(true) end)

local bHeaders=CreateFrame("Frame",nil,right)
bHeaders:SetPoint("TOPLEFT",bSettings,"BOTTOMLEFT",0,-12)
bHeaders:SetPoint("TOPRIGHT",right,"TOPRIGHT",-LIST_RIGHT_INSET,-12)
bHeaders:SetHeight(18)
local bName=W:Button(bHeaders,"Name",BNAME_W,18,function() Page:ToggleBucketSort("name") end)
bName:SetPoint("LEFT",bHeaders,"LEFT",B_START_X,0)
local bStacks=W:Button(bHeaders,"Stacks",BSTACKS_W,18,function() Page:ToggleBucketSort("stacks") end)
bStacks:SetPoint("LEFT",bName,"RIGHT",4,0)
local bList=CreateFrame("Frame",nil,right)
bList:SetPoint("TOPLEFT",bHeaders,"BOTTOMLEFT",0,4)
bList:SetPoint("TOPRIGHT",right,"TOPRIGHT",-LIST_RIGHT_INSET,4)
bList:SetPoint("BOTTOMRIGHT",right,"BOTTOMRIGHT",-LIST_RIGHT_INSET,10)
bList:SetPoint("BOTTOMLEFT",right,"BOTTOMLEFT",10,10)
local bColSep=CreateFrame("Frame",nil,right)
bColSep:SetPoint("TOPLEFT",bHeaders,"TOPLEFT",0,0)
bColSep:SetPoint("BOTTOMRIGHT",bList,"BOTTOMRIGHT",0,0)
local function bvline(x)
  local t=bColSep:CreateTexture(nil,"BORDER")
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  local lc=T.c.line
  t:SetVertexColor(lc[1],lc[2],lc[3],0.6)
  t:SetPoint("TOPLEFT",bColSep,"TOPLEFT",x,0)
  t:SetPoint("BOTTOMLEFT",bColSep,"BOTTOMLEFT",x,0)
  t:SetWidth(1)
  return t
end
local _bseps={bvline(BSEP1),bvline(BSEP2)}
local function _UpdateBSeps()
  local base=bColSep:GetLeft()
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
    t:SetPoint("TOPLEFT",bColSep,"TOPLEFT",x,0)
    t:SetPoint("BOTTOMLEFT",bColSep,"BOTTOMLEFT",x,0)
  end
  setLine(_bseps[1],mid(bName,bStacks))
  local rightEdge=bHeaders:GetRight()
  if rightEdge then setLine(_bseps[2],(bStacks:GetRight()+rightEdge)/2) end
end
local bScroll=CreateFrame("ScrollFrame","EchoArchitectBucketScroll",right,"FauxScrollFrameTemplate")
bScroll:ClearAllPoints()
bScroll:SetPoint("TOP",bList,"TOP",0,0)
bScroll:SetPoint("BOTTOM",bList,"BOTTOM",0,0)
bScroll:SetPoint("LEFT",bList,"RIGHT",6,0)
bScroll:SetPoint("RIGHT",right,"RIGHT",-10,0)
bScroll:SetScript("OnVerticalScroll",function(self,offset)
  FauxScrollFrame_OnVerticalScroll(self,offset,26,function() Page:UpdateBucketList(false) end)
end)
local bsb=_G[bScroll:GetName().."ScrollBar"]
if bsb then
  bsb:ClearAllPoints()
  bsb:SetPoint("TOPLEFT",bScroll,"TOPLEFT",0,0)
  bsb:SetPoint("BOTTOMLEFT",bScroll,"BOTTOMLEFT",0,0)
  T:ApplyScrollBar(bsb)
  bsb:Show()
end
bList:EnableMouseWheel(true)
bScroll:EnableMouseWheel(true)
local function bwheel(delta)
  local sb=_G[bScroll:GetName().."ScrollBar"]
  if sb and sb.GetValue and sb.SetValue then
    local v=tonumber(sb:GetValue() or 0) or 0
    sb:SetValue(v-(delta*26*3))
  end
end
bList:SetScript("OnMouseWheel",function(_,delta) bwheel(delta) end)
bScroll:SetScript("OnMouseWheel",function(_,delta) bwheel(delta) end)
local bRows={}
local BROWS=8
local function parseKey(k)
  local sid=tonumber(string.match(k,"^(%d+):") or 0) or 0
  local q=tonumber(string.match(k,":(%d+)$") or 0) or 0
  return sid,q
end
bucketTooltip=function(owner,bid,anchor)
  if not GameTooltip or not bid then return end
  local pr=EA.Profiles:GetActiveProfile()
  local b=pr and pr.buckets and pr.buckets[bid] or nil
  if not b then return end
  GameTooltip:ClearLines()
  GameTooltip:SetOwner(owner,anchor or "ANCHOR_CURSOR")
  GameTooltip:AddLine(b.name or "Bucket")
  local keys=b.echoKeys or {}
  local list={}
  for k,_ in pairs(keys) do list[#list+1]=k end
  table.sort(list)
  for i=1,#list do
    local sid,q=parseKey(list[i])
    local nm=(GetSpellInfo and GetSpellInfo(sid)) or tostring(sid)
    local col=DB:QualityColor(q)
    local ic=(GetSpellTexture and GetSpellTexture(sid))
    if not ic and GetSpellInfo then local _,_,t=GetSpellInfo(sid) ic=t end
    local iconTxt=ic and ("|T"..ic..":14|t ") or ""
    GameTooltip:AddLine(iconTxt..col..nm.."|r")
  end
  GameTooltip:Show()
end
for i=1,BROWS do
  local r=CreateFrame("Frame",nil,bList)
  r:SetHeight(24)
  r:SetPoint("TOPLEFT",bList,"TOPLEFT",0,-(i-1)*26)
  r:SetPoint("TOPRIGHT",bList,"TOPRIGHT",0,-(i-1)*26)
  local bg=r:CreateTexture(nil,"BACKGROUND")
  bg:SetPoint("TOPLEFT",r,"TOPLEFT",0,0)
  bg:SetPoint("BOTTOMRIGHT",r,"BOTTOMRIGHT",5,0)
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetVertexColor(0,0,0,0)
  local icon=r:CreateTexture(nil,"ARTWORK")
  icon:SetWidth(B_ICON_W) icon:SetHeight(B_ICON_W)
  icon:SetPoint("LEFT",r,"LEFT",4,0)
  icon:SetTexture("Interface\\Icons\\inv_misc_1h_bucket_c_01")
  local nameBtn=W:Button(r,"",BNAME_W,20,function() if r._bid then Page:SelectBucket(r._bid) end end)
  nameBtn:SetPoint("LEFT",icon,"RIGHT",6,0)
  local sBox=W:EditBox(r,BSTACKS_W,20)
  sBox:SetJustifyH("CENTER")
  sBox:SetPoint("LEFT",nameBtn,"RIGHT",GAP,0)
  local del=CreateFrame("Button",nil,r)
  del:SetWidth(20) del:SetHeight(20)
  del:SetPoint("RIGHT",r,"RIGHT",12,0)
  del._fs=T:Font(del,14,"OUTLINE")
  del._fs:SetAllPoints(del)
  del._fs:SetText("|cffff4040X|r")
  del:SetScript("OnClick",function()
    if r._bid then Page:ConfirmDeleteBucket(r._bid) end
  end)
  local function showTip() if r._bid then bucketTooltip(nameBtn,r._bid,"ANCHOR_CURSOR") end end
  local function hideTip() if GameTooltip then GameTooltip:Hide() end end
  nameBtn:SetScript("OnEnter",showTip)
  nameBtn:SetScript("OnLeave",hideTip)
  r._bg=bg
  r._icon=icon
  r._nameBtn=nameBtn
  r._stacks=sBox
  r._del=del
  bRows[i]=r
end
Page._bucketSelName=selName
Page._bucketRows=bRows
Page._bucketScroll=bScroll
Page._bucketListFrame=bList
Page._bucketSettings=bSettings
local function setSelected(entry,row)
  Page._selected=entry
  Page._selectedKey=entry and entry.key or nil
  for i=1,ROWS do
    local r=rows[i]
    if Page._selectedKey and r._entry and r._entry.key==Page._selectedKey then
      r._bg:SetVertexColor(0,0.55,0.7,0.18)
    else
      r._bg:SetVertexColor(0,0,0,0)
    end
  end
  local col=DB:QualityColor(entry.quality)
  insIcon:SetTexture(entry.icon or "Interface\\Buttons\\WHITE8X8")
  insName:SetText("")
  insSub:SetText("")
  local meta=DB:GetPerkMeta(entry.spellId) or {}
  local cm=tonumber(meta.classMask or 0) or 0
  local allMask=(DB and DB.ALL_CLASS_MASK) or 1535
  local isAll=(cm==0 or cm==allMask)
  local req=tonumber(meta.requiredSpell or 0) or 0
  local reqName=req>0 and (GetSpellInfo and (GetSpellInfo(req) or tostring(req)) or tostring(req)) or "None"
  local e=Log:GetDB().perEcho[entry.key] or {}
  vSpell:SetText(tostring(entry.spellId))
  vQuality:SetText(col..QualityName(entry.quality).."|r")
  local pr=EA.Profiles:GetActiveProfile()
  local bid=pr and pr.echoBucket and pr.echoBucket[entry.key]
  local bname=bid and pr and pr.buckets and pr.buckets[bid] and pr.buckets[bid].name or nil
  do
    local c="|cff19d1e6"
    if vBucketBtn and vBucketBtn._fs then
      vBucketBtn._bid=bid
      if bid and bname then
        vBucketBtn._fs:SetText(c..tostring(bname).."|r")
        vBucketBtn._tipText=nil
        if bIcon then bIcon:SetTexture("Interface\\Icons\\inv_misc_1h_bucket_c_01") bIcon:SetVertexColor(1,1,1,1) end
      else
        vBucketBtn._fs:SetText("|cffaaaaaaNone|r")
        vBucketBtn._tipText="No bucket assigned."
        if bIcon then bIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") bIcon:SetVertexColor(1,1,1,1) end
      end
    end
  end
  vStacks:SetText(tostring(meta.maxStack or 0))
  do
    if vReqBtn and vReqBtn._fs then
      vReqBtn._sid=req>0 and req or nil
      local ic=req>0 and (GetSpellTexture and GetSpellTexture(req)) or nil
      if not ic and GetSpellInfo and req>0 then local _,_,t=GetSpellInfo(req) ic=t end
      if ic then rIcon:SetTexture(ic) rIcon:SetVertexColor(1,1,1,1) vReqBtn._tipText=nil else rIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") rIcon:SetVertexColor(1,1,1,1) vReqBtn._tipText="No unlock required." end
      if req>0 then vReqBtn._fs:SetText("|cff19d1e6"..tostring(reqName).."|r") else vReqBtn._fs:SetText("|cffaaaaaaNone|r") end
    end
  end
	if Page._clsIcons then
		if isAll then
			for i=1,#Page._clsIcons do local tx=Page._clsIcons[i]._tex if tx then tx:SetDesaturated(false) tx:SetVertexColor(1,1,1,1) tx:SetAlpha(1) end end
		else
			for i=1,#Page._clsIcons do
				local ic=Page._clsIcons[i]
				local bitv=(Page._classBits and ic and ic._class and Page._classBits[ic._class]) or 0
				local ok=(bitv>0 and bit and bit.band and bit.band(cm,bitv)~=0)
				local tx=ic and ic._tex
				if tx then
					if ok then tx:SetDesaturated(false) tx:SetVertexColor(1,1,1,1) tx:SetAlpha(1) else tx:SetDesaturated(true) tx:SetVertexColor(1,1,1,1) tx:SetAlpha(0.35) end
				end
			end
		end
	end
	if vSeen then vSeen:SetText(tostring(e.seen or 0)) end
	if vPicked then vPicked:SetText(tostring(e.picked or 0)) end
	if vBan then vBan:SetText(tostring(e.banished or 0)) end
  if insTip then
    insTip:ClearLines()
    if insTip.SetHyperlink then
      insTip:SetHyperlink("spell:"..tostring(entry.spellId))
    elseif insTip.SetSpellByID then
      insTip:SetSpellByID(entry.spellId)
    else
      local nm=GetSpellInfo and GetSpellInfo(entry.spellId)
      if nm and insTip.SetText then insTip:SetText(nm) end
    end
    insTip:Show()
  end
  Page:UpdateBucketPanel()
end
function Page:ToggleSort(key)
  local db=EchoArchitect_CharDB
  local cur=db.ui.library.sortKey
  if cur==key then
    db.ui.library.sortAsc=not db.ui.library.sortAsc
  else
    db.ui.library.sortKey=key
    if key=="weight" then
      db.ui.library.sortAsc=false
    else
      db.ui.library.sortAsc=true
    end
  end
  self:UpdateList(true)
end
function Page:BuildData()
  local db=EchoArchitect_CharDB
  local showAll=db.ui.library.showAll
  local search=db.ui.library.search or ""
  local raw=DB:IterPerks(showAll)
  local list={}
  for i=1,#raw do
    local ent=raw[i]
    if ent then
      ent.key=DB:MakeKey(ent.spellId,ent.quality)
      list[#list+1]=ent
    end
  end
  local mode=db.ui.library.searchMode or "name"
  if search~="" then
    local s=string.lower(search)
    local out={}
    for i=1,#list do
      local ent=list[i]
      local ok=false
      if mode=="tooltip" then
        local tip=W:GetSpellTooltipText(ent.spellId)
        if tip~="" and string.find(tip,s,1,true) then ok=true end
      else
        if string.find(string.lower(ent.name),s,1,true) then ok=true end
        local qn=string.lower(QualityName(ent.quality) or "")
        if (not ok) and qn~="" and string.find(qn,s,1,true) then ok=true end
      end
      if ok then out[#out+1]=ent end
    end
    list=out
  end
  local pr=EA.Profiles:GetActiveProfile()
  local sortKey=db.ui.library.sortKey
  local asc=db.ui.library.sortAsc
  table.sort(list,function(a,b)
  if a==b then return false end
  if not a then return false end
  if not b then return true end
  local function nrm(x) return string.lower(tostring(x or "")) end
  local an=nrm(a.name)
  local bn=nrm(b.name)
  local function bucketName(ent)
    local id=pr and pr.echoBucket and pr.echoBucket[ent.key]
    return nrm(id and pr and pr.buckets and pr.buckets[id] and pr.buckets[id].name or "")
  end
  local function weight(ent)
    return tonumber(pr and pr.weights and pr.weights[ent.key] or 0) or 0
  end
  local function blk(ent)
    return (pr and pr.blacklist and pr.blacklist[ent.key]) and 1 or 0
  end
  local function cmp(av,bv,isAsc)
    if av==bv then return nil end
    if isAsc then return av<bv end
    return av>bv
  end
  local sk=sortKey
  local isAsc=asc
  local av,bv,res
  if sk=="quality" then
    av=tonumber(a.quality or 0) or 0
    bv=tonumber(b.quality or 0) or 0
    res=cmp(av,bv,isAsc)
    if res~=nil then return res end
    res=cmp(an,bn,true)
    if res~=nil then return res end
    return tostring(a.key or "")<tostring(b.key or "")
  elseif sk=="weight" then
    av=weight(a) bv=weight(b)
    res=cmp(av,bv,isAsc)
    if res~=nil then return res end
    res=cmp(an,bn,true)
    if res~=nil then return res end
    av=tonumber(a.quality or 0) or 0
    bv=tonumber(b.quality or 0) or 0
    res=cmp(av,bv,true)
    if res~=nil then return res end
    return tostring(a.key or "")<tostring(b.key or "")
  elseif sk=="blacklist" then
    av=blk(a) bv=blk(b)
    res=cmp(av,bv,isAsc)
    if res~=nil then return res end
    res=cmp(an,bn,true)
    if res~=nil then return res end
    av=tonumber(a.quality or 0) or 0
    bv=tonumber(b.quality or 0) or 0
    res=cmp(av,bv,true)
    if res~=nil then return res end
    return tostring(a.key or "")<tostring(b.key or "")
  elseif sk=="bucket" then
    av=bucketName(a) bv=bucketName(b)
    res=cmp(av,bv,isAsc)
    if res~=nil then return res end
    res=cmp(an,bn,true)
    if res~=nil then return res end
    av=tonumber(a.quality or 0) or 0
    bv=tonumber(b.quality or 0) or 0
    res=cmp(av,bv,true)
    if res~=nil then return res end
    return tostring(a.key or "")<tostring(b.key or "")
  else
    res=cmp(an,bn,isAsc)
    if res~=nil then return res end
    av=tonumber(a.quality or 0) or 0
    bv=tonumber(b.quality or 0) or 0
    res=cmp(av,bv,isAsc)
    if res~=nil then return res end
    return tostring(a.key or "")<tostring(b.key or "")
  end
end)

  return list
end

function Page:EnsureBuckets()
  local pr=EA.Profiles:GetActiveProfile()
  if not pr then return nil end
  pr.buckets=pr.buckets or {}
  pr.echoBucket=pr.echoBucket or {}
  return pr
end
local function bucketIdsSorted(pr)
  local ids={}
  for id,b in pairs(pr.buckets or {}) do
    if type(b)=="table" then ids[#ids+1]=id end
  end
  table.sort(ids,function(a,b)
    local an=pr.buckets[a] and pr.buckets[a].name or ""
    local bn=pr.buckets[b] and pr.buckets[b].name or ""
    return tostring(an)<tostring(bn)
  end)
  return ids
end
function Page:CreateBucket(name)
  local pr=self:EnsureBuckets()
  if not pr then return end
  local id="b"..tostring(time and time() or math.random(100000,999999))..tostring(math.random(100,999))
  pr.buckets[id]={name=name,maxStacks=1,enabled=true,echoKeys={}}
  self._bucketEditId=id
  self:UpdateBucketPanel()
  self:UpdateList(true)
end
function Page:DeleteCurrentBucket()
  local pr=self:EnsureBuckets()
  if not pr then return end
  local id=self._bucketEditId
  if not id or not pr.buckets[id] then return end
  for k,v in pairs(pr.echoBucket) do
    if v==id then pr.echoBucket[k]=nil end
  end
  pr.buckets[id]=nil
  self._bucketEditId=nil
  self:UpdateBucketPanel()
  self:UpdateList(true)
end
function Page:SetEchoBucket(echoKey,bucketId)
  local pr=self:EnsureBuckets()
  if not pr then return end
  local prev=pr.echoBucket[echoKey]
  if prev and pr.buckets[prev] and pr.buckets[prev].echoKeys then
    pr.buckets[prev].echoKeys[echoKey]=nil
  end
  if not bucketId then
    pr.echoBucket[echoKey]=nil
  else
    pr.echoBucket[echoKey]=bucketId
    pr.buckets[bucketId]=pr.buckets[bucketId] or {name="Bucket",maxStacks=1,echoKeys={}}
    pr.buckets[bucketId].echoKeys=pr.buckets[bucketId].echoKeys or {}
    pr.buckets[bucketId].echoKeys[echoKey]=true
    self._bucketEditId=bucketId
  end
  self:UpdateBucketPanel()
  self:UpdateList(false)
end
function Page:ShowBucketMenu(anchor,echoKey,fromInspector)
  local pr=self:EnsureBuckets()
  if not pr then return end
  local menu={}
  menu[#menu+1]={text="None",func=function() self:SetEchoBucket(echoKey,nil) end,notCheckable=true}
  local ids=bucketIdsSorted(pr)
  for i=1,#ids do
    local id=ids[i]
    local b=pr.buckets[id]
    local nm=b and b.name or ""
    menu[#menu+1]={text=nm~="" and nm or id,func=function() self:SetEchoBucket(echoKey,id) end,notCheckable=true}
  end
  if UIDropDownMenu_CreateInfo and EasyMenu then
    if not self._bucketMenuFrame then
      self._bucketMenuFrame=CreateFrame("Frame","EchoArchitectBucketMenuFrame",UIParent,"UIDropDownMenuTemplate")
    end
    EasyMenu(menu,self._bucketMenuFrame,"cursor",0,0,"MENU",2)
  end
end
function Page:ToggleBucketSort(key)
  local db=EchoArchitect_CharDB
  db.ui.library.bucketSortAsc=not db.ui.library.bucketSortAsc
  db.ui.library.bucketSortKey=key
  self:UpdateBucketList(true)
end
function Page:BuildBucketData()
  local pr=self:EnsureBuckets()
  if not pr or not pr.buckets then return {} end
  local t={}
  for bid,b in pairs(pr.buckets) do
    if type(b)=="table" then
      local ct=0
      if type(b.echoKeys)=="table" then
        for _ in pairs(b.echoKeys) do ct=ct+1 end
      end
      local cap=tonumber(b.maxStacks or 0) or 0
      t[#t+1]={id=bid,name=tostring(b.name or bid),echoes=ct,stacks=cap}
    end
  end
  local db=EchoArchitect_CharDB
  local sk=db.ui.library.bucketSortKey or "name"
  local asc=db.ui.library.bucketSortAsc~=false
  table.sort(t,function(a,b)
    local va=a[sk] or ""
    local vb=b[sk] or ""
    if type(va)=="string" then va=string.lower(va) end
    if type(vb)=="string" then vb=string.lower(vb) end
    if asc then return va<vb end
    return va>vb
  end)
  return t
end
function Page:SelectBucket(bid)
  self._bucketSelId=bid
  self:UpdateBucketPanel()
end
function Page:ConfirmDeleteBucket(bid)
  if not bid then return end
  self._pendingDeleteBucket=bid
  if not StaticPopupDialogs["ECHOARCH_BUCKET_DELETE"] then
    StaticPopupDialogs["ECHOARCH_BUCKET_DELETE"]={
      text="Delete this bucket?",
      button1=YES,
      button2=NO,
      OnAccept=function()
        local pr=Page:EnsureBuckets()
        local id=Page._pendingDeleteBucket
        if pr and id and pr.buckets and pr.buckets[id] then
          pr.buckets[id]=nil
          if pr.echoBucket then
            for ek,b in pairs(pr.echoBucket) do
              if b==id then pr.echoBucket[ek]=nil end
            end
          end
          if Page._bucketSelId==id then Page._bucketSelId=nil end
          Page._pendingDeleteBucket=nil
          Page:UpdateBucketPanel()
          Page:UpdateList(true)
        end
      end,
      timeout=0,
      whileDead=1,
      hideOnEscape=1
    }
  end
  StaticPopup_Show("ECHOARCH_BUCKET_DELETE")
end
function Page:UpdateBucketList(rebuild)
  local pr=self:EnsureBuckets()
  if not pr then return end
  if rebuild or not self._bucketData then
    self._bucketData=self:BuildBucketData()
  end
  local data=self._bucketData or {}
  local q=self._bucketSearch and self._bucketSearch:GetText() or ""
  q=strlower(strtrim(q))
  if q~="" then
    local f={}
    for j=1,#data do
      local b=data[j]
      if b and b.name and strfind(strlower(b.name),q,1,true) then f[#f+1]=b end
    end
    data=f
  end
  self._bucketShown=data
  FauxScrollFrame_Update(self._bucketScroll,#data,BROWS,26)
  local offset=FauxScrollFrame_GetOffset(self._bucketScroll) or 0
  for i=1,BROWS do
    local r=self._bucketRows[i]
    local idx=offset+i
    local e=data[idx]
    if e then
      r:Show()
      r._bid=e.id
      if self._bucketSelId and self._bucketSelId==e.id then
        r._bg:SetVertexColor(0,0.55,0.7,0.18)
      else
        r._bg:SetVertexColor(0,0,0,0)
      end
      local col="|cff00ccff"
      r._nameBtn._fs:SetText(col..e.name.."|r")
      r._stacks._eaSetting=true
      r._stacks:SetText(tostring(e.stacks or 0))
      r._stacks._eaSetting=false
      W:BindCommit(r._stacks,function(ed)
        local v=tonumber(ed:GetText() or 0)
        if v==nil then return end
        if v<0 then v=0 end
        if v>80 then v=80 end
        if pr.buckets and pr.buckets[e.id] then
          pr.buckets[e.id].maxStacks=v
        end
      end)
      r._stacks._eaIdx=idx
      r._stacks:SetScript("OnTabPressed",function(self)
        local dir=IsShiftKeyDown() and -1 or 1
        Page:FocusBucketStackIndex(self._eaIdx,dir)
      end)
    else
      r._bid=nil
      r:Hide()
    end
  end
end
function Page:UpdateBucketPanel()
  local pr=self:EnsureBuckets()
  if not pr then return end
  local bid=self._bucketSelId
  local b=bid and pr.buckets and pr.buckets[bid] or nil
  if self._bucketSelName and self._bucketSelName.SetText then
    self._bucketSelName:SetText(b and b.name or "None")
    local c=T.c.heirloom or {0,0.8,1,1}
    if b then self._bucketSelName:SetTextColor(c[1],c[2],c[3],c[4]) else self._bucketSelName:SetTextColor(T.c.text[1],T.c.text[2],T.c.text[3],T.c.text[4]) end
  end
  self:UpdateBucketList(true)
end
function Page:UpdateRow(r)
  if not r._entry then return end
  local pr=EA.Profiles:GetActiveProfile()
  local col=DB:QualityColor(r._entry.quality)
  r._nameBtn._fs:SetText(col..r._entry.name.."|r")
  r._qBox:SetText(col..QualityName(r._entry.quality).."|r")
  r._wBox._eaSetting=true
  r._wBox:SetText(tostring(pr.weights[r._key] or 0))
  r._wBox._eaSetting=false
  r._blk:SetValue(pr.blacklist[r._key]==true)
  local bid=pr.echoBucket and pr.echoBucket[r._key]
  local bn=bid and pr.buckets and pr.buckets[bid] and pr.buckets[bid].name or "None"
  if r._bucketBtn and r._bucketBtn.SetText then r._bucketBtn:SetText(bn) end
end

function Page:_ScrollToIndex(scroll,idx,rowH,rowsN,total)
  if not scroll or not idx or not total then return 0 end
  local maxOff=total-rowsN
  if maxOff<0 then maxOff=0 end
  local want=idx-rowsN
  if want<0 then want=0 end
  if idx<=want then want=idx-1 end
  local off=FauxScrollFrame_GetOffset(scroll) or 0
  if idx<off+1 then
    off=idx-1
  elseif idx>off+rowsN then
    off=idx-rowsN
  end
  if off<0 then off=0 end
  if off>maxOff then off=maxOff end
  if scroll.ScrollBar and scroll.ScrollBar.SetValue then
    scroll.ScrollBar:SetValue(off*rowH)
  end
  return off
end

function Page:_QueueFocus(kind,idx)
  self._pendingFocusKind=kind
  self._pendingFocusIdx=idx
  if self._focusDriver then return end
  self._focusDriver=CreateFrame("Frame",nil,UIParent)
  self._focusDriver:SetScript("OnUpdate",function()
    self._focusDriver:SetScript("OnUpdate",nil)
    self._focusDriver:Hide()
    self._focusDriver=nil
    local k=self._pendingFocusKind
    local i=self._pendingFocusIdx
    self._pendingFocusKind=nil
    self._pendingFocusIdx=nil
    if k=="weight" then
      local off=FauxScrollFrame_GetOffset(scroll) or 0
      local row=i-off
      local r=row and rows[row]
      if r and r._wBox and r._wBox.SetFocus then
        r._wBox:SetFocus()
        r._wBox:HighlightText()
      end
    elseif k=="stacks" then
      local off=FauxScrollFrame_GetOffset(self._bucketScroll) or 0
      local row=i-off
      local r=row and self._bucketRows and self._bucketRows[row]
      if r and r._stacks and r._stacks.SetFocus then
        r._stacks:SetFocus()
        r._stacks:HighlightText()
      end
    end
  end)
end

function Page:FocusWeightIndex(idx,dir)
  if not self._data then return end
  local total=#self._data
  if total<=0 then return end
  local n=idx+(dir or 1)
  if n<1 then n=total end
  if n>total then n=1 end
  self:_ScrollToIndex(scroll,n,26,ROWS,total)
  self:UpdateList(false)
  self:_QueueFocus("weight",n)
end

function Page:FocusBucketStackIndex(idx,dir)
  local data=self._bucketShown or {}
  local total=#data
  if total<=0 then return end
  local n=idx+(dir or 1)
  if n<1 then n=total end
  if n>total then n=1 end
  self:_ScrollToIndex(self._bucketScroll,n,26,BROWS,total)
  self:UpdateBucketList(false)
  self:_QueueFocus("stacks",n)
end

function Page:UpdateList(rebuild)
  local db=EchoArchitect_CharDB
  db.ui.library.search=eSearch:GetText() or ""
  if rebuild or not self._data then
    self._data=self:BuildData()
  end
  local total=#self._data
  local elig=DB:IterPerks(false)
  local eligSet={}
  for i=1,#elig do
    local e=elig[i]
    if e then
      eligSet[DB:MakeKey(e.spellId,e.quality)]=true
    end
  end
  local shown=0
  for i=1,total do
    local e=self._data[i]
    local k=e and (e.key or DB:MakeKey(e.spellId,e.quality))
    if k and eligSet[k] then shown=shown+1 end
  end
  local all=DB:IterPerks(true)
  local allN=#all
  local _,cls=UnitClass("player")
  local hex=(DB.CLASS_COLORS and DB.CLASS_COLORS[cls]) or "FFFFFF"
  local gray="C0C0C0"
  if vShown and vShown.SetText then
    vShown:SetText("Echoes Shown: |cff"..hex..tostring(shown).."|r |cff"..gray.."("..tostring(allN)..")|r")
  end
  FauxScrollFrame_Update(scroll,total,ROWS,26)
  local offset=FauxScrollFrame_GetOffset(scroll)
  chkAll:SetValue(db.ui.library.showAll)
  for i=1,ROWS do
    local idx=offset+i
    local r=rows[i]
    local ent=self._data[idx]
    if ent then
      r:Show()
      r._entry=ent
      r._key=DB:MakeKey(ent.spellId,ent.quality)
      ent.key=r._key
      if self._selectedKey and self._selectedKey==r._key then
        r._bg:SetVertexColor(0,0.55,0.7,0.18)
      else
        r._bg:SetVertexColor(0,0,0,0)
      end
      if type(ent.icon)=="string" then
        r._icon:SetTexture(ent.icon)
      else
        r._icon:SetTexture("Interface\\Buttons\\WHITE8X8")
        r._icon:SetVertexColor(0,0,0,0)
      end
      r._nameBtn:SetScript("OnClick",function() setSelected(ent,r) end)
            W:AttachSpellTooltip(r._nameBtn,function() return ent.spellId end)
      W:BindCommit(r._wBox,function(ed)
        local p=EA.Profiles:GetActiveProfile()
        local v=tonumber(ed:GetText() or "")
        if v then p.weights[r._key]=v end
      end)
      r._wBox._eaIdx=idx
      r._wBox:SetScript("OnTabPressed",function(self)
        local dir=IsShiftKeyDown() and -1 or 1
        Page:FocusWeightIndex(self._eaIdx,dir)
      end)
      self:UpdateRow(r)
    else
      if r and r._bg then r._bg:SetVertexColor(0,0,0,0) end
      r:Hide()
    end
  end
end
scroll:SetScript("OnVerticalScroll",function(self,offset)
  FauxScrollFrame_OnVerticalScroll(self,offset,26,function() Page:UpdateList(false) end)
end)
eSearch:SetScript("OnTextChanged",function() Page:UpdateList(true) end)
Page:SetScript("OnShow",function()
  _UpdateSeps()
  _UpdateBSeps()
  local db=EchoArchitect_CharDB
  db.ui=db.ui or {}
  db.ui.library=db.ui.library or {}
  chkAll:SetValue(db.ui.library.showAll)
  local sm=db.ui.library.searchMode or "name"
  if sm=="tooltip" then searchModeBtn:SetText("Search: Tooltip") else searchModeBtn:SetText("Search: Name+Rarity") end
  eSearch:SetText(db.ui.library.search or "")
  Page:UpdateList(true)
  Page:UpdateBucketPanel()
end)
Page:SetScript("OnSizeChanged",function() _UpdateSeps() _UpdateBSeps() end)
Win:RegisterPage("library",Page)