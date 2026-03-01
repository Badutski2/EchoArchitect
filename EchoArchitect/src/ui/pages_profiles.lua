local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
local UI=EA.UI
local Win=UI.Window
local W=UI.Widgets
local T=UI.Theme
local Page=CreateFrame("Frame",nil,UIParent)
T:ApplyPanel(Page,"bg")
local hdr=W:Label(Page,"",16)
hdr:SetPoint("TOPLEFT",Page,"TOPLEFT",0,0)
hdr:Hide()
local left=CreateFrame("Frame",nil,Page)
left:SetPoint("TOPLEFT",Page,"TOPLEFT",0,0)
left:SetPoint("BOTTOMLEFT",Page,"BOTTOMLEFT",0,0)
left:SetWidth(320)
T:ApplyPanel(left,"navy")
local right=CreateFrame("Frame",nil,Page)
right:SetPoint("TOPLEFT",left,"TOPRIGHT",10,0)
right:SetPoint("BOTTOMRIGHT",Page,"BOTTOMRIGHT",0,0)
T:ApplyPanel(right,"navy")
local list=CreateFrame("Frame",nil,left)
list:SetPoint("TOPLEFT",left,"TOPLEFT",10,-10)
list:SetPoint("BOTTOMRIGHT",left,"BOTTOMRIGHT",-10,140)
local ROWS=14
local rows={}
for i=1,ROWS do
  local r=CreateFrame("Button",nil,list)
  r:SetHeight(24)
  r:SetPoint("TOPLEFT",list,"TOPLEFT",0,-(i-1)*26)
  r:SetPoint("TOPRIGHT",list,"TOPRIGHT",0,-(i-1)*26)
  T:ApplyButton(r)
  local fs=T:Font(r,12,"")
  fs:SetPoint("LEFT",r,"LEFT",8,0)
  r._fs=fs
  rows[i]=r
end
local selName=nil
local function refresh()
  local db=EchoArchitect_CharDB
  local names={}
  for k in pairs(db.profiles or {}) do names[#names+1]=k end
  table.sort(names)
  for i=1,ROWS do
    local r=rows[i]
    local n=names[i]
    if n then
      r:Show()
      r._name=n
      local tag=(db.activeProfile==n) and "  |cff1eff00(Active)|r" or ""
      r._fs:SetText(n..tag)
      local c=UI.Theme.c
      r._selected=(selName==n)
      if r._bg then
        if r._selected then
          r._bg:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.22)
        else
          r._bg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.9)
        end
      end
      r:SetScript("OnEnter",function()
        r._bg:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.22)
      end)
      r:SetScript("OnLeave",function()
        if r._selected then
          r._bg:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.22)
        else
          r._bg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.9)
        end
      end)
      r:SetScript("OnClick",function()
        selName=n
        refresh()
      end)
    else
      r:Hide()
    end
  end
end
local act=W:Button(left,"Set Active",120,26,function()
  if not selName then return end
  EA.Profiles:SetActiveProfile(selName)
  refresh()
end)
act:SetPoint("BOTTOMLEFT",left,"BOTTOMLEFT",10,106)
act:SetPoint("BOTTOMRIGHT",left,"BOTTOMRIGHT",-10,106)
local del=W:Button(left,"Delete",120,26,function()
  if not selName then return end
  EA.Profiles:DeleteProfile(selName)
  selName=nil
  refresh()
end)
del:SetPoint("BOTTOMLEFT",left,"BOTTOMLEFT",10,76)
del:SetPoint("BOTTOMRIGHT",left,"BOTTOMRIGHT",-10,76)
local create=CreateFrame("Frame",nil,left)
create:SetPoint("BOTTOMLEFT",left,"BOTTOMLEFT",10,10)
create:SetPoint("BOTTOMRIGHT",left,"BOTTOMRIGHT",-10,10)
create:SetHeight(54)
local nameLbl=W:Label(create,"Name",12)
nameLbl:SetPoint("LEFT",create,"LEFT",0,0)
local btnCol=CreateFrame("Frame",nil,create)
btnCol:SetWidth(120)
btnCol:SetPoint("TOPRIGHT",create,"TOPRIGHT",0,0)
btnCol:SetPoint("BOTTOMRIGHT",create,"BOTTOMRIGHT",0,0)
local newBox=W:EditBox(create,160,20)
newBox:SetPoint("LEFT",nameLbl,"RIGHT",10,0)
newBox:SetPoint("RIGHT",btnCol,"LEFT",-10,0)
local newBtn=W:Button(btnCol,"Create New",120,24,function()
  local n=newBox:GetText() or ""
  if n=="" then return end
  EA.Profiles:EnsureProfile(n)
  refresh()
end)
newBtn:SetPoint("TOPRIGHT",btnCol,"TOPRIGHT",0,0)
local cloneBtn=W:Button(btnCol,"Copy Selected",120,24,function()
  if not selName then return end
  local n=newBox:GetText() or ""
  if n=="" then return end
  EA.Profiles:CloneProfile(selName,n)
  refresh()
end)
cloneBtn:SetPoint("BOTTOMRIGHT",btnCol,"BOTTOMRIGHT",0,0)
local detHdr=W:Label(right,"",16)
detHdr:SetPoint("TOPLEFT",right,"TOPLEFT",10,-10)
detHdr:Hide()
local expBtn=W:Button(right,"Export Selected",140,22,function()
  if not selName then return end
  local s=EA.Profiles:ExportProfile(selName)
  Page._io:SetText(s)
  Page._io:HighlightText()
end)
expBtn:SetPoint("TOPLEFT",right,"TOPLEFT",10,-10)
local impBtn=W:Button(right,"Import To Selected",160,22,function()
  if not selName then return end
  local s=Page._io:GetText() or ""
  local ok,err=EA.Profiles:ImportProfile(selName,s)
  if not ok then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Import failed|r "..tostring(err))
  end
  refresh()
end)
impBtn:SetPoint("LEFT",expBtn,"RIGHT",10,0)
local ioScroll=CreateFrame("ScrollFrame","EchoArchitectProfileIOScroll",right,"UIPanelScrollFrameTemplate")
ioScroll:SetPoint("TOPLEFT",expBtn,"BOTTOMLEFT",0,-10)
ioScroll:SetPoint("BOTTOMRIGHT",right,"BOTTOMRIGHT",-10,10)
local io=CreateFrame("EditBox","EchoArchitectProfileIOBox",ioScroll)
io:SetMultiLine(true)
io:SetFont(STANDARD_TEXT_FONT,12,"")
io:SetAutoFocus(false)
io:SetWidth(520)
io:SetHeight(800)
io:SetTextInsets(6,6,6,6)
io:SetScript("OnEscapePressed",function() io:ClearFocus() end)
io:SetScript("OnTextChanged",function(self)
  local text=self:GetText() or ""
  local lines=1
  if text~="" then
    lines=1
    for _ in string.gmatch(text,"\n") do lines=lines+1 end
  end
  local _,fs=self:GetFont()
  fs=tonumber(fs) or 12
  local h=lines*(fs+2)+20
  if h<800 then h=800 end
  self:SetHeight(h)
end)
ioScroll:SetScrollChild(io)
local bg=ioScroll:CreateTexture(nil,"BACKGROUND")
bg:SetAllPoints(ioScroll)
bg:SetTexture("Interface\\Buttons\\WHITE8X8")
bg:SetVertexColor(0.03,0.04,0.06,0.95)
Page._io=io
function Page:ShowDetails()
  if not selName then return end
end
Page:SetScript("OnShow",function() refresh() end)
Win:RegisterPage("profiles",Page)
