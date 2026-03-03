local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
local UI=EA.UI
local Win=UI.Window
local W=UI.Widgets
local T=UI.Theme
local DB=EA.DB

UI._HiddenParent=UI._HiddenParent or CreateFrame("Frame","EchoArchitectHiddenParent",UIParent)
UI._HiddenParent:Hide()
local Page=CreateFrame("Frame",nil,UI._HiddenParent)
T:ApplyPanel(Page,"bg")
Page:Hide()

local qualityInfo={
  [0]={name="Common",color={1,1,1}},
  [1]={name="Uncommon",color={0.12,1.0,0.12}},
  [2]={name="Rare",color={0.0,0.44,1.0}},
  [3]={name="Epic",color={0.64,0.22,1.0}},
  [4]={name="Legendary",color={1.0,0.58,0.10}},
}
local function getTooltipUtils()
  local u=_G and _G.utils
  if type(u)=="table" and (u.GetSpellDescription or u.GetStackedSpellDescription) then return u end
  local pe=_G and _G.ProjectEbonhold
  if type(pe)=="table" then
    local u2=pe.utils or pe.Utils or pe.util or pe.Util
    if type(u2)=="table" and (u2.GetSpellDescription or u2.GetStackedSpellDescription) then return u2 end
  end
  return nil
end

local function getResolvedDescription(d)
  local u=getTooltipUtils()
  if not d or not u then return nil end
  local insts={}
  local sbq=d.sidByQuality
  local bq=d.byQuality or {}
  if type(bq)=="table" then
    for q=4,0,-1 do
      local c=tonumber(bq[q] or 0) or 0
      if c>0 then
        local sid=0
        if type(sbq)=="table" then sid=tonumber(sbq[q] or 0) or 0 end
        if sid<=0 then sid=tonumber(d.displaySpellId or d.spellId or 0) or 0 end
        if sid>0 then insts[#insts+1]={spellId=sid,stacks=c} end
      end
    end
  end
  if #insts>1 and u.GetStackedSpellDescription then
    return u.GetStackedSpellDescription(insts,500)
  end
  if #insts==1 and u.GetSpellDescription then
    local it=insts[1]
    return u.GetSpellDescription(it.spellId,500,it.stacks)
  end
  if u.GetSpellDescription then
    local sid=tonumber(d.displaySpellId or d.spellId or 0) or 0
  if sid<=0 and type(d.sidByQuality)=="table" then
    for q=4,0,-1 do
      local s2=tonumber(d.sidByQuality[q] or 0) or 0
      if s2>0 then sid=s2 break end
    end
  end
    if sid>0 then return u.GetSpellDescription(sid,500,1) end
  end
  return nil
end

local function colorizeResolvedDesc(desc)
  desc=tostring(desc or "")
  if desc=="" then return "" end
  local gold="|cffffd200"
  local green="|cff00ff00"
  local plain=desc:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  local pick=plain:match("dealing%s+([%d%.,]*%.?%d+)")
  if not pick then
    local maxStr=nil
    local maxVal=nil
    for n in plain:gmatch("(%d[%d%.,]*%.?%d*)") do
      local v=tonumber((n:gsub(",","")))
      if v and (not maxVal or v>maxVal) then maxVal=v maxStr=n end
    end
    pick=maxStr
  end
  local out=plain
  if pick and pick~="" then
    local done=false
    out=out:gsub("(%d[%d%.,]*%.?%d*)",function(n)
      if done or n~=pick then return n end
      done=true
      return green..n..gold
    end)
  end
  return gold..out.."|r"
end





local function showCurrentEchoTooltip(owner,d)
  if not GameTooltip or not d then return end
  local u=getTooltipUtils()
  local desc=nil
  if u then desc=getResolvedDescription(d) end
  local sid=tonumber(d.displaySpellId or d.spellId or 0) or 0
  if sid<=0 and type(d.sidByQuality)=="table" then
    for q=4,0,-1 do
      local s2=tonumber(d.sidByQuality[q] or 0) or 0
      if s2>0 then sid=s2 break end
    end
  end
  GameTooltip:ClearLines()
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
  local nm=tostring(d.name or "")
  if nm=="" and sid>0 then nm=GetSpellInfo(sid) or "" end
  local bestQ=0
  local bq=d.byQuality
  if type(bq)=="table" then
    for q=4,0,-1 do
      local c=tonumber(bq[q] or 0) or 0
      if c>0 then bestQ=q break end
    end
  end
  local qi=qualityInfo[bestQ] or qualityInfo[0]
  if nm~="" then GameTooltip:AddLine(nm,qi.color[1],qi.color[2],qi.color[3]) end
  if desc and desc~="" then
    GameTooltip:AddLine(colorizeResolvedDesc(desc),1,1,1,true)
  elseif sid>0 and GameTooltip.SetHyperlink then
    GameTooltip:SetHyperlink("spell:"..tostring(sid))
  end
  if type(bq)=="table" then
    local a=false
    for q=4,0,-1 do
      local c=tonumber(bq[q] or 0) or 0
      if c>0 then
        if not a then GameTooltip:AddLine(" ") a=true end
        local q2=qualityInfo[q] or qualityInfo[0]
        GameTooltip:AddLine(tostring(c).." "..tostring(q2.name),q2.color[1],q2.color[2],q2.color[3])
      end
    end
  end
  if d.lockedTotal and d.lockedTotal>0 then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Locked: "..tostring(d.lockedTotal),1,0.82,0.1,true)
  end
  GameTooltip:Show()
end

local function getGranted()
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.GetGrantedPerks then
    local ok,res=pcall(ProjectEbonhold.PerkService.GetGrantedPerks)
    if ok and type(res)=="table" then return res end
  end
  return {}
end

local function getLocked()
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.GetLockedPerks then
    local ok,res=pcall(ProjectEbonhold.PerkService.GetLockedPerks)
    if ok and type(res)=="table" then return res end
  end
  return {}
end

local function getMaxSlots()
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.GetMaximumPermanentEchoes then
    local ok,res=pcall(ProjectEbonhold.PerkService.GetMaximumPermanentEchoes)
    if ok then return tonumber(res or 0) or 0 end
  end
  return 0
end

local function requestRefresh()
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.RequestGrantedPerks then
    pcall(ProjectEbonhold.PerkService.RequestGrantedPerks)
  end
end

local _afterFrame=nil
local function afterDelay(sec,fn)
  if type(fn)~="function" then return end
  sec=tonumber(sec or 0) or 0
  if sec<=0 then pcall(fn) return end
  if not _afterFrame then
    _afterFrame=CreateFrame("Frame",nil,UIParent)
    _afterFrame.q={}
    _afterFrame:SetScript("OnUpdate",function(self,el)
      local q=self.q
      if not q or #q==0 then return end
      el=tonumber(el) or 0
      for i=#q,1,-1 do
        local t=q[i]
        t.t=t.t-el
        if t.t<=0 then
          table.remove(q,i)
          pcall(t.f)
        end
      end
    end)
  end
  local q=_afterFrame.q
  q[#q+1]={t=sec,f=fn}
end

local pad=12

local top=CreateFrame("Frame",nil,Page)
top:SetPoint("TOPLEFT",Page,"TOPLEFT",0,0)
top:SetPoint("TOPRIGHT",Page,"TOPRIGHT",0,0)
top:SetHeight(46)
T:ApplyPanel(top,"navy")

local title=W:Label(top,"Current Echoes",16)
title:SetPoint("LEFT",top,"LEFT",10,0)

local btnRefresh=W:Button(top,"Refresh",90,22,function() requestRefresh() Page:Refresh(true) end)
btnRefresh:SetPoint("RIGHT",top,"RIGHT",-10,0)

local searchLabel=W:Label(top,"Search",12)
searchLabel:SetPoint("RIGHT",btnRefresh,"LEFT",-14,0)
local searchBox=W:EditBox(top,210,20)
searchBox:SetPoint("RIGHT",searchLabel,"LEFT",-8,0)

local function uiState()
  local db=EchoArchitect_CharDB
  db.ui=db.ui or {}
  db.ui.currentEchoes=db.ui.currentEchoes or {}
  local s=db.ui.currentEchoes
  if s.sortKey==nil then s.sortKey="name" end
  if s.sortAsc==nil then s.sortAsc=true end
  if s.disableEchoesPanel==nil then s.disableEchoesPanel=false end
  if s.listLockedFirst==nil then s.listLockedFirst=false end
  return s
end


local disablePanel=W:Check(top,"Disable Echoes Panel",function(self,v)
  local st=uiState()
  st.disableEchoesPanel=v and true or false
  Page:ApplyEchoesPanelDisable()
end)
disablePanel:SetPoint("RIGHT",searchBox,"LEFT",-14,0)
disablePanel:SetWidth(170)

local listLockedFirst=W:Check(top,"List Locked First",function(self,v)
  local st=uiState()
  st.listLockedFirst=v and true or false
  Page:Refresh(true)
end)
listLockedFirst:SetPoint("RIGHT",disablePanel,"LEFT",-14,0)
listLockedFirst:SetWidth(140)

local listWrap=CreateFrame("Frame",nil,Page)
listWrap:SetPoint("TOPLEFT",top,"BOTTOMLEFT",0,0)
listWrap:SetPoint("BOTTOMRIGHT",Page,"BOTTOMRIGHT",0,0)


local headers=CreateFrame("Frame",nil,listWrap)
headers:SetPoint("TOPLEFT",listWrap,"TOPLEFT",10,-10)
headers:SetPoint("TOPRIGHT",listWrap,"TOPRIGHT",-26,-10)
headers:SetHeight(18)

function Page:ToggleSort(key)
  local s=uiState()
  if s.sortKey==key then
    s.sortAsc=not s.sortAsc
  else
    s.sortKey=key
    if key=="total" or key=="locked" or key=="q4" or key=="q3" or key=="q2" or key=="q1" or key=="q0" then
      s.sortAsc=false
    else
      s.sortAsc=true
    end
  end
  self:Refresh(true)
end

function Page:ApplyEchoesPanelDisable()
  local st=uiState()
  local dis=st.disableEchoesPanel and true or false
  local pr=_G and _G["ProjectEbonholdPlayerRunFrame"] or nil
  local ef=_G and _G["ProjectEbonholdEmpowermentFrame"] or nil
  if pr and pr.empowermentHeader then
    if dis then
      pr.empowermentHeader:Hide()
      pr.empowermentHeader:EnableMouse(false)
    else
      pr.empowermentHeader:Show()
      pr.empowermentHeader:EnableMouse(true)
    end
  end
  if ef then
    if dis then
      ef:Hide()
      ef:EnableMouse(false)
    else
      ef:EnableMouse(true)
    end
  end
end

local hLock=W:Button(headers,"Locked",54,18,function() Page:ToggleSort("locked") end)
hLock:SetPoint("LEFT",headers,"LEFT",6,0)
local hName=W:Button(headers,"Echo",260,18,function() Page:ToggleSort("name") end)
hName:SetPoint("LEFT",headers,"LEFT",90,0)

local hL=W:Button(headers,"Legendary",66,18,function() Page:ToggleSort("q4") end)
hL:SetPoint("RIGHT",headers,"RIGHT",-270,0)

local hE=W:Button(headers,"Epic",52,18,function() Page:ToggleSort("q3") end)
hE:SetPoint("RIGHT",headers,"RIGHT",-218,0)

local hR=W:Button(headers,"Rare",52,18,function() Page:ToggleSort("q2") end)
hR:SetPoint("RIGHT",headers,"RIGHT",-166,0)

local hU=W:Button(headers,"Uncommon",70,18,function() Page:ToggleSort("q1") end)
hU:SetPoint("RIGHT",headers,"RIGHT",-96,0)

local hC=W:Button(headers,"Common",60,18,function() Page:ToggleSort("q0") end)
hC:SetPoint("RIGHT",headers,"RIGHT",-36,0)

local hTotal=W:Button(headers,"Total",54,18,function() Page:ToggleSort("total") end)
hTotal:SetPoint("RIGHT",headers,"RIGHT",-6,0)

local rows={}

local function layoutColumns()
  local w=tonumber(headers:GetWidth() or 0) or 0
  if w<=0 then w=680 end
  local gap=6
  local favW=54
  local favLeft=6
  local iconLeft=favLeft+favW+gap
  local nameLeft=iconLeft+18+gap
  local rightPad=6
  local rem=w-nameLeft-rightPad
  if rem<260 then rem=260 end
  local remNoGap=rem-(gap*6)
  if remNoGap<200 then remNoGap=200 end
  local nameW=math.floor(remNoGap*0.32)
  if nameW<120 then nameW=120 end
  local numRem=remNoGap-nameW
  local numW=math.floor(numRem/6)
  if numW<44 then numW=44 end
  hLock:ClearAllPoints()
  hLock:SetWidth(favW)
  hLock:SetPoint("LEFT",headers,"LEFT",favLeft,0)
  local x=nameLeft
  hName:ClearAllPoints()
  hName:SetWidth(nameW)
  hName:SetPoint("LEFT",headers,"LEFT",x,0)
  x=x+nameW+gap
  local function place(btn)
    btn:ClearAllPoints()
    btn:SetWidth(numW)
    btn:SetPoint("LEFT",headers,"LEFT",x,0)
    x=x+numW+gap
  end
  place(hL)
  place(hE)
  place(hR)
  place(hU)
  place(hC)
  place(hTotal)
  for i=1,#rows do
    local r=rows[i]
    r._iconBtn:ClearAllPoints()
    r._iconBtn:SetPoint("LEFT",r,"LEFT",iconLeft,0)
    if r._favBox then
      r._favBox:ClearAllPoints()
      r._favBox:SetSize(favW,20)
      r._favBox:SetPoint("LEFT",r,"LEFT",favLeft,0)
    end
    if r._nameBtn then
      r._nameBtn:ClearAllPoints()
      r._nameBtn:SetWidth(nameW)
      r._nameBtn:SetPoint("LEFT",r,"LEFT",nameLeft,0)
    end
    local cx=nameLeft+nameW+gap
    local function placeCell(cell)
      if not cell then return end
      cell:ClearAllPoints()
      cell:SetWidth(numW)
      cell:SetPoint("LEFT",r,"LEFT",cx,0)
      cx=cx+numW+gap
    end
    placeCell(r._c4)
    placeCell(r._c3)
    placeCell(r._c2)
    placeCell(r._c1)
    placeCell(r._c0)
    placeCell(r._total)
  end
end

headers:SetScript("OnSizeChanged",function() layoutColumns() end)


local list=CreateFrame("Frame",nil,listWrap)
list:SetPoint("TOPLEFT",headers,"BOTTOMLEFT",0,-8)
list:SetPoint("BOTTOMRIGHT",listWrap,"BOTTOMRIGHT",-26,10)

local scroll=CreateFrame("ScrollFrame","EchoArchitectCurrentEchoesScroll",listWrap,"FauxScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",list,"TOPRIGHT",6,0)
scroll:SetPoint("BOTTOMLEFT",list,"BOTTOMRIGHT",6,0)
scroll:SetPoint("RIGHT",listWrap,"RIGHT",-10,0)
scroll:SetScript("OnVerticalScroll",function(self,offset)
  FauxScrollFrame_OnVerticalScroll(self,offset,26,function() Page:Refresh(false) end)
end)
local sb=_G[scroll:GetName().."ScrollBar"]
if sb then
  sb:ClearAllPoints()
  sb:SetPoint("TOPLEFT",scroll,"TOPLEFT",0,0)
  sb:SetPoint("BOTTOMLEFT",scroll,"BOTTOMLEFT",0,0)
  T:ApplyScrollBar(sb)
end

list:EnableMouseWheel(true)
scroll:EnableMouseWheel(true)
local function wheel(delta)
  local sbb=_G[scroll:GetName().."ScrollBar"]
  if sbb and sbb.GetValue and sbb.SetValue then
    local v=tonumber(sbb:GetValue() or 0) or 0
    sbb:SetValue(v-(delta*26*3))
  end
end
list:SetScript("OnMouseWheel",function(_,delta) wheel(delta) end)
scroll:SetScript("OnMouseWheel",function(_,delta) wheel(delta) end)

 local ROWS=16

local function solid(parent,layer,r,g,b,a)
  local tx=parent:CreateTexture(nil,layer)
  tx:SetTexture("Interface\\Buttons\\WHITE8X8")
  tx:SetVertexColor(r,g,b,a)
  tx:SetAllPoints(parent)
  return tx
end

local function makeRow(i)
  local row=CreateFrame("Button",nil,list)
  row:SetHeight(26)
  row:SetPoint("TOPLEFT",list,"TOPLEFT",0,-((i-1)*26))
  row:SetPoint("TOPRIGHT",list,"TOPRIGHT",0,-((i-1)*26))
  solid(row,"BACKGROUND",0.03,0.04,0.06,(i%2==0) and 0.55 or 0.35)
  local iconBtn=CreateFrame("Button",nil,row)
  iconBtn:SetSize(18,18)
  iconBtn:SetPoint("LEFT",row,"LEFT",66,0)
  local icon=iconBtn:CreateTexture(nil,"ARTWORK")
  icon:SetAllPoints(iconBtn)
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  row._iconBtn=iconBtn
  local favBox=CreateFrame("Frame",nil,row)
  favBox:SetSize(54,20)
  favBox:SetPoint("LEFT",row,"LEFT",6,0)
  row._favBox=favBox
  local lock=W:Check(row,"",function(self,v)
    local d=row._data
    if not d then return end
    local ps=ProjectEbonhold and ProjectEbonhold.PerkService
    if not ps then return end
    if v then
      local max=getMaxSlots()
      local used=0
      local locked=getLocked()
      if type(locked)=="table" then
        for _,ent in pairs(locked) do
          local sid=tonumber(type(ent)=="table" and ent.spellId or 0) or 0
          if sid>0 then used=used+1 end
        end
      end
      if max>0 and used>=max then
        if Page and Page._warn then
          Page._warn:SetText("|cffff2020Locked Echoes slots full|r")
          Page._warn:Show()
          afterDelay(2.5,function() if Page and Page._warn then Page._warn:Hide() end end)
        end
        self:SetValue(false)
        return
      end
      local sid=tonumber(d.displaySpellId or 0) or 0
      if sid>0 and ps.LockPerk then
        local ok,res=pcall(ps.LockPerk,sid,1)
        if ok and res then
          afterDelay(0.4,function() requestRefresh() Page:Refresh(true) end)
          return
        end
      end
      self:SetValue(false)
    else
      local sid=tonumber(d.lockedSpellId or 0) or 0
      if sid==0 then sid=tonumber(d.displaySpellId or 0) or 0 end
      if sid>0 and ps.UnlockPerk then
        local ok,res=pcall(ps.UnlockPerk,sid)
        if ok and res then
          afterDelay(0.4,function() requestRefresh() Page:Refresh(true) end)
          return
        end
      end
      self:SetValue(true)
    end
  end)
  lock:SetWidth(20)
  lock:SetPoint("CENTER",favBox,"CENTER",0,0)

  local lockHit=CreateFrame("Button",nil,row)
  lockHit:SetAllPoints(favBox)
  lockHit:SetScript("OnClick",function() lock._btn:Click() end)
  row._fav=lock

  local nameBtn=W:Button(row,"",260,20,function() end)
  nameBtn._fs:SetJustifyH("LEFT")
  nameBtn._fs:ClearAllPoints()
  nameBtn._fs:SetPoint("LEFT",nameBtn,"LEFT",6,0)
  nameBtn:EnableMouse(true)
  nameBtn:SetFrameLevel(row:GetFrameLevel()+5)

  local c4=W:BoxButton(row,"",66,20)
  c4._fs:SetJustifyH("CENTER")
  local c3=W:BoxButton(row,"",52,20)
  c3._fs:SetJustifyH("CENTER")
  local c2=W:BoxButton(row,"",52,20)
  c2._fs:SetJustifyH("CENTER")
  local c1=W:BoxButton(row,"",70,20)
  c1._fs:SetJustifyH("CENTER")
  local c0=W:BoxButton(row,"",60,20)
  c0._fs:SetJustifyH("CENTER")
  local total=W:BoxButton(row,"",54,20)
  total._fs:SetJustifyH("CENTER")
  c4:EnableMouse(false)
  c3:EnableMouse(false)
  c2:EnableMouse(false)
  c1:EnableMouse(false)
  c0:EnableMouse(false)
  total:EnableMouse(false)

  row._icon=icon
  row._nameBtn=nameBtn
  row._c4=c4
  row._c3=c3
  row._c2=c2
  row._c1=c1
  row._c0=c0
  row._total=total
  row:RegisterForClicks("LeftButtonUp","RightButtonUp")


  if row._iconBtn then
    row._iconBtn:SetScript("OnEnter",function(self)
      local d=row._data
      if not d then return end
      showCurrentEchoTooltip(self,d)
    end)
row._iconBtn:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  end
  if row._nameBtn then
    row._nameBtn:SetScript("OnEnter",function(self)
      local d=row._data
      if not d then return end
      showCurrentEchoTooltip(self,d)
    end)
row._nameBtn:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  end
  row:SetScript("OnClick",function(self,button)
    local d=self._data
    if not d then return end
    if IsShiftKeyDown() and button=="LeftButton" and (d.displaySpellId or d.spellId) then
      local editBox=ChatFrameEditBox
      if not editBox or not editBox:IsShown() then editBox=ChatFrame1EditBox end
      local q=tonumber(d.quality or 0) or 0
      local marker="{echo:"..tostring(tonumber(d.displaySpellId or d.spellId or 0) or 0)..":"..tostring(q).."}"
      if editBox and editBox:IsShown() then
        editBox:Insert(marker)
      else
        ChatFrame_OpenChat("")
        afterDelay(0.1,function()
          local eb=ChatFrame1EditBox
          if eb then eb:Insert(marker) end
        end)
      end
    end
  end)
  return row
end

for i=1,ROWS do rows[i]=makeRow(i) end

local function normalizeLockedArray(locked)
  if type(locked)~="table" then return {} end
  if #locked>0 then
    local out={}
    for i=1,#locked do out[i]=locked[i] end
    return out
  end
  local function copyEnt(src)
    if type(src)~="table" then return src end
    local dst={}
    for k,v in pairs(src) do dst[k]=v end
    return dst
  end
  local tmp={}
  for k,v in pairs(locked) do
    if type(v)=="table" then
      local ent=copyEnt(v)
      ent._key=k
      tmp[#tmp+1]=ent
    end
  end
  table.sort(tmp,function(a,b)
    local ak=tonumber(a.slotIndex or a.index or a._key or 0) or 0
    local bk=tonumber(b.slotIndex or b.index or b._key or 0) or 0
    if ak~=bk then return ak<bk end
    return (tonumber(a.spellId or 0) or 0)<(tonumber(b.spellId or 0) or 0)
  end)
  return tmp
end

local function buildRows(granted,locked,search)
  local map={}
  local s=string.lower(tostring(search or ""))
  local function touch(sid,q)
    sid=tonumber(sid or 0) or 0
    if sid<=0 then return nil end
    local n,_,ic=GetSpellInfo(sid)
    local key=nil
    if n and n~="" then key=string.lower(n) end
    if not key then key="spell:"..tostring(sid) end
    local e=map[key]
    if not e then
      e={key=key,name=n or ("Spell "..tostring(sid)),icon=ic,byQuality={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0},sidByQuality={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0},total=0,lockedTotal=0,quality=0,best=0,displaySpellId=sid}
      map[key]=e
    end
    q=tonumber(q or 0) or 0
    if q>=tonumber(e.quality or 0) then
      e.quality=q
      if n and n~="" then e.name=n end
      if ic then e.icon=ic end
      e.displaySpellId=sid
    end
    return e
  end
  for _,instances in pairs(granted or {}) do
    if type(instances)=="table" then
      for i=1,#instances do
        local inst=instances[i]
        local sid=tonumber(inst and inst.spellId or 0) or 0
        local q=tonumber(inst and inst.quality or 0) or 0
        local st=tonumber(inst and inst.stack or 1) or 1
        local e=touch(sid,q)
        if e then
          e.total=e.total+st
          e.byQuality[q]=(tonumber(e.byQuality[q] or 0) or 0)+st
          if e.sidByQuality then e.sidByQuality[q]=sid end
          if q>e.quality then e.quality=q end
        end
      end
    end
  end
  local lockedArr=normalizeLockedArray(locked)
  for i=1,#lockedArr do
    local ent=lockedArr[i]
    local sid=tonumber(ent and ent.spellId or 0) or 0
    local q=tonumber(ent and ent.quality or 0) or 0
    local e=touch(sid,q)
    if e then
      local st=tonumber(ent and ent.stack or ent.stacks or 1) or 1 if st<1 then st=1 end
e.total=e.total+st
e.lockedTotal=(tonumber(e.lockedTotal or 0) or 0)+st
      if (not e.lockedQuality) or q>=e.lockedQuality then e.lockedQuality=q e.lockedSpellId=sid end
e.byQuality[q]=(tonumber(e.byQuality[q] or 0) or 0)+st
          if e.sidByQuality then e.sidByQuality[q]=sid end
      if q>e.quality then e.quality=q end
    end
  end
  local out={}
  for _,e in pairs(map) do
    local bestQ=tonumber(e.quality or 0) or 0
    e.best=tonumber(e.byQuality[bestQ] or 0) or 0
    local nm=tostring(e.name or "")
    if s=="" or string.find(string.lower(nm),s,1,true) then
      out[#out+1]=e
    end
  end
  local st=uiState()
  local sk=st.sortKey or "name"
  local asc=st.sortAsc~=false
  table.sort(out,function(a,b)
    if a==b then return false end
    if not a then return false end
    if not b then return true end
    local function cmp(av,bv,isAsc)
      if av==bv then return nil end
      if isAsc then return av<bv end
      return av>bv
    end
    local an=string.lower(tostring(a.name or ""))
    local bn=string.lower(tostring(b.name or ""))
    local al=(a.lockedTotal and a.lockedTotal>0) and true or false
    local bl=(b.lockedTotal and b.lockedTotal>0) and true or false
    if st.listLockedFirst and al~=bl then return al end
    local res
    if sk=="name" then
      res=cmp(an,bn,asc)
      if res~=nil then return res end
      return tostring(a.displaySpellId or a.spellId or "")<tostring(b.displaySpellId or b.spellId or "")
    elseif sk=="locked" then
      res=cmp((tonumber(a.lockedTotal or 0) or 0),(tonumber(b.lockedTotal or 0) or 0),asc)
      if res~=nil then return res end
      res=cmp(an,bn,true)
      if res~=nil then return res end
      return tostring(a.displaySpellId or a.spellId or "")<tostring(b.displaySpellId or b.spellId or "")
    elseif sk=="total" then
      res=cmp(tonumber(a.total or 0) or 0,tonumber(b.total or 0) or 0,asc)
      if res~=nil then return res end
      res=cmp(an,bn,true)
      if res~=nil then return res end
      return tostring(a.displaySpellId or a.spellId or "")<tostring(b.displaySpellId or b.spellId or "")
    elseif sk=="q4" or sk=="q3" or sk=="q2" or sk=="q1" or sk=="q0" then
      local qn=0
      if sk=="q4" then qn=4 elseif sk=="q3" then qn=3 elseif sk=="q2" then qn=2 elseif sk=="q1" then qn=1 else qn=0 end
      res=cmp(tonumber(a.byQuality and a.byQuality[qn] or 0) or 0,tonumber(b.byQuality and b.byQuality[qn] or 0) or 0,asc)
      if res~=nil then return res end
      res=cmp(an,bn,true)
      if res~=nil then return res end
      return tostring(a.displaySpellId or a.spellId or "")<tostring(b.displaySpellId or b.spellId or "")
    else
      res=cmp(an,bn,asc)
      if res~=nil then return res end
      return tostring(a.displaySpellId or a.spellId or "")<tostring(b.displaySpellId or b.spellId or "")
    end
  end)
  return out
end

local function setRow(r,d)
  r._data=d
  if not d then
    r:Hide()
    return
  end
  r:Show()
  if d.icon then r._icon:SetTexture(d.icon) else r._icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
  local q=tonumber(d.quality or 0) or 0
  local nm=tostring(d.name or "")
  if DB and DB.QualityColor then nm=DB:QualityColor(q)..nm.."|r" end
  r._nameBtn:SetText(nm)
  local bq=d.byQuality or {}
  local function fmt(qn)
    local c=tonumber(bq[qn] or 0) or 0
    if c<=0 then return "" end
    if DB and DB.QualityColor then return DB:QualityColor(qn)..tostring(c).."|r" end
    return tostring(c)
  end
  if r._c4 then r._c4:SetText(fmt(4)) end
  if r._c3 then r._c3:SetText(fmt(3)) end
  if r._c2 then r._c2:SetText(fmt(2)) end
  if r._c1 then r._c1:SetText(fmt(1)) end
  if r._c0 then r._c0:SetText(fmt(0)) end
  local tot=tonumber(d.total or 0) or 0
  local best=nil
  local bq=d.byQuality or {}
  if tot>0 then
    if tonumber(bq[4] or 0)>0 then best=4
    elseif tonumber(bq[3] or 0)>0 then best=3
    elseif tonumber(bq[2] or 0)>0 then best=2
    elseif tonumber(bq[1] or 0)>0 then best=1
    elseif tonumber(bq[0] or 0)>0 then best=0
    end
  end
  if best~=nil and DB and DB.QualityColor then
    r._total:SetText(DB:QualityColor(best)..tostring(tot).."|r")
  else
    r._total:SetText(tostring(tot))
  end

local isLocked=(tonumber(d.lockedTotal or 0) or 0)>0
if r._fav then r._fav:SetValue(isLocked) end
end

function Page:Refresh(resetScroll)
  local granted=getGranted()
  local locked=getLocked()
  local data=buildRows(granted,locked,searchBox:GetText())
  if resetScroll then FauxScrollFrame_SetOffset(scroll,0) end
  FauxScrollFrame_Update(scroll,#data,ROWS,26)
  local offset=FauxScrollFrame_GetOffset(scroll)
  for i=1,ROWS do
    local idx=i+offset
    setRow(rows[i],data[idx])
  end
end


local function calcHash()
  local g=getGranted()
  local l=getLocked()
  local parts={}
  for name,inst in pairs(g) do
    if type(inst)=="table" then
      local total=0
      local maxQ=0
      for i=1,#inst do
        local it=inst[i]
        local q=tonumber(it and it.quality or 0) or 0
        local st=tonumber(it and it.stack or 1) or 1
        total=total+st
        if q>maxQ then maxQ=q end
      end
      parts[#parts+1]=tostring(name)..":"..tostring(total)..":"..tostring(maxQ)
    end
  end
  if type(l)=="table" then
    if #l>0 then
      for i=1,#l do
        local e=l[i]
        if type(e)=="table" then
          parts[#parts+1]="L"..tostring(i)..":"..tostring(e.spellId or 0)..":"..tostring(e.quality or 0)..":"..tostring(e.stack or e.stacks or 1)
        end
      end
    else
      for k,e in pairs(l) do
        if type(e)=="table" then
          parts[#parts+1]="L"..tostring(k)..":"..tostring(e.spellId or 0)..":"..tostring(e.quality or 0)..":"..tostring(e.stack or e.stacks or 1)
        end
      end
    end
  end
  table.sort(parts)
  return table.concat(parts,"|")
end

Page._hash=nil
Page._t=0
Page:SetScript("OnUpdate",function(self,el)
  if not self:IsShown() then return end
  self._t=self._t+(tonumber(el) or 0)
  if self._t<0.6 then return end
  self._t=0
  local h=calcHash()
  if h~=self._hash then
    self._hash=h
    self:Refresh(false)
  end
end)

W:BindCommit(searchBox,function()
  Page:Refresh(true)
end)

Page:SetScript("OnShow",function()
  Page._hash=nil
  Page._t=0
  requestRefresh()
  local s=uiState()
  if disablePanel then disablePanel:SetValue(s.disableEchoesPanel and true or false) end
  if listLockedFirst then listLockedFirst:SetValue(s.listLockedFirst and true or false) end
  Page:ApplyEchoesPanelDisable()
  afterDelay(0.01,function() layoutColumns() end)
  Page:Refresh(true)
end)


local function enforcePageAttach()
  if not Page or not Page.GetParent then return end
  local p=Page:GetParent()
  if p==UIParent or p==nil or p==UI._HiddenParent then
    local w=Win and Win.Create and Win:Create()
    if w and w._content then
      Page:Hide()
      Page:SetParent(w._content)
      Page:ClearAllPoints()
      Page:SetPoint("TOPLEFT",w._content,"TOPLEFT",10,-10)
      Page:SetPoint("BOTTOMRIGHT",w._content,"BOTTOMRIGHT",-10,10)
      Page:Hide()
      if w._pageFrames then w._pageFrames["current_echoes"]=Page end
    else
      Page:Hide()
    end
  else
    Page:Hide()
  end
end

local _attachEv=CreateFrame("Frame",nil,UIParent)
_attachEv:RegisterEvent("PLAYER_LOGIN")
_attachEv:RegisterEvent("PLAYER_ENTERING_WORLD")
_attachEv:SetScript("OnEvent",function() enforcePageAttach() end)


Win:RegisterPage("current_echoes",Page)