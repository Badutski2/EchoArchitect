local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.UI=EA.UI or {}
local UI=EA.UI
local T=UI.Theme
local W=UI.Widgets
UI.Window=UI.Window or {}
local Win=UI.Window
Win._pending=Win._pending or {}
local function getDB()
  return EchoArchitect_CharDB
end
local function navState()
  local db=getDB()
  if not db then return {collapsed=false} end
  db.ui=db.ui or {}
  db.ui.window=db.ui.window or {}
  local w=db.ui.window
  if w.navCollapsed==nil then w.navCollapsed=false end
  return w
end
local function btnStyle(b)
  local c=UI.Theme.c
  b:SetScript("OnEnter",function(self)
    if not self._selected then self._bg:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.22) end
  end)
  b:SetScript("OnLeave",function(self)
    if self._selected then
      self._bg:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.28)
    else
      self._bg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.9)
    end
  end)
end
function Win:Create()
  if self.frame then return self.frame end
  local f=CreateFrame("Frame","EchoArchitectMainFrame",UIParent)
  f:SetWidth(1080)
  f:SetHeight(560)
  f:SetPoint("CENTER",UIParent,"CENTER",0,0)
  if not self._esc then
    if UISpecialFrames then
      tinsert(UISpecialFrames,"EchoArchitectMainFrame")
      tinsert(UISpecialFrames,"EchoArchitectLogbookExportFrame")
      tinsert(UISpecialFrames,"EchoArchitectLogbookImportFrame")
    end
    self._esc=true
  end
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function() f:StartMoving() end)
  f:SetScript("OnDragStop",function()
    f:StopMovingOrSizing()
    local db=getDB()
    local ui=db and db.ui and db.ui.window
    if ui then
      local _,_,_,x,y=f:GetPoint()
      ui.x=x ui.y=y
    end
  end)
  T:ApplyPanel(f,"bg")
  local top=CreateFrame("Frame",nil,f)
  top:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
  top:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
  top:SetHeight(42)
  T:ApplyPanel(top,"navy")
  local title=T:Font(top,16,"")
  title:SetPoint("LEFT",top,"LEFT",12,0)
  title:SetText("EchoArchitect")
  local close=W:Button(top,"X",28,22,function() f:Hide() end)
  close:SetPoint("RIGHT",top,"RIGHT",-10,0)
  local body=CreateFrame("Frame",nil,f)
  body:SetPoint("TOPLEFT",top,"BOTTOMLEFT",0,0)
  body:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0)
  local nav=CreateFrame("Frame",nil,body)
  nav:SetPoint("TOPLEFT",body,"TOPLEFT",0,0)
  nav:SetPoint("BOTTOMLEFT",body,"BOTTOMLEFT",0,0)
  T:ApplyPanel(nav,"navy")
  local content=CreateFrame("Frame",nil,body)
  content:SetPoint("TOPLEFT",nav,"TOPRIGHT",0,0)
  content:SetPoint("BOTTOMRIGHT",body,"BOTTOMRIGHT",0,0)
  content:EnableMouse(true)
  T:ApplyPanel(content,"bg")
  local toggle=W:Button(top,"<",24,22,function()
    Win:ToggleNav()
  end)
  toggle:SetPoint("LEFT",title,"RIGHT",10,0)
  local list={
    {id="dashboard",label="Dashboard"},
    {id="settings",label="Settings"},
    {id="library",label="Echo Library"},
    {id="history",label="History"},
    {id="logbook",label="Logbook"},
    {id="profiles",label="Profiles"},
  }
  f._nav=nav
  f._content=content
  f._navButtons={}
  f._pageFrames={}
  f._navList=list
  f._toggle=toggle
  local y=-12
  for i=1,#list do
    local def=list[i]
    local b=W:Button(nav,def.label,160,26,function() Win:ShowTab(def.id) end)
    b:SetPoint("TOPLEFT",nav,"TOPLEFT",10,y)
    b:SetPoint("TOPRIGHT",nav,"TOPRIGHT",-10,y)
    y=y-32
    b._fullLabel=def.label
    btnStyle(b)
    f._navButtons[def.id]=b
  end
  self.frame=f
  self.pages=content
  local db=getDB()
  if db and db.ui and db.ui.window then
    local uiw=db.ui.window
    if uiw.scale then f:SetScale(uiw.scale) end
    if uiw.x and uiw.y then f:ClearAllPoints() f:SetPoint("CENTER",UIParent,"CENTER",uiw.x,uiw.y) end
  end
  f:Hide()
  for i=1,#self._pending do
    local p=self._pending[i]
    self:_AttachPage(p.id,p.frame)
  end
  self._pending={}
  self:ApplyNavState()
  return f
end
function Win:ApplyNavState()
  local f=self:Create()
  local s=navState()
  local collapsed=s.navCollapsed and true or false
  local w=collapsed and 46 or 180
  f._nav:SetWidth(w)
  f._toggle._label:SetText(collapsed and ">" or "<")
  for id,b in pairs(f._navButtons) do
    if collapsed then
      b._label:SetText("")
      b:SetHeight(30)
    else
      b._label:SetText(b._fullLabel or "")
      b:SetHeight(26)
    end
  end
end
function Win:ToggleNav()
  local s=navState()
  s.navCollapsed=not s.navCollapsed
  self:ApplyNavState()
end
function Win:_AttachPage(id,frame)
  local f=self.frame or self:Create()
  frame:Hide()
  frame:SetParent(f._content)
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT",f._content,"TOPLEFT",10,-10)
  frame:SetPoint("BOTTOMRIGHT",f._content,"BOTTOMRIGHT",-10,10)
  frame:Hide()
  f._pageFrames[id]=frame
end
function Win:RegisterPage(id,frame)
  if self.frame then
    self:_AttachPage(id,frame)
  else
    self._pending[#self._pending+1]={id=id,frame=frame}
  end
end
function Win:ShowTab(id)
  local f=self:Create()
  for k,p in pairs(f._pageFrames) do
    if k==id then p:Show() else p:Hide() end
  end
  for bid,b in pairs(f._navButtons) do
    b._selected=(bid==id)
    b:GetScript("OnLeave")(b)
  end
  local db=getDB()
  if db and db.ui and db.ui.window then db.ui.window.tab=id end
end
function Win:Toggle()
  local f=self:Create()
  if f:IsShown() then f:Hide() else f:Show() end
  local db=getDB()
  if db and db.ui and db.ui.window then db.ui.window.shown=f:IsShown() end
end

function Win:ApplyScale()
  local f=self.frame
  if not f then return end
  local db=getDB()
  local s=db and db.ui and db.ui.window and tonumber(db.ui.window.scale)
  if s then f:SetScale(s) end
end