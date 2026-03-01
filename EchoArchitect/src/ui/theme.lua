local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.UI=EA.UI or {}
local UI=EA.UI
UI.Theme=UI.Theme or {}
local T=UI.Theme
T.c={
  bg={0.06,0.06,0.07,0.95},
  panel={0.08,0.09,0.12,0.95},
  navy={0.05,0.08,0.14,0.95},
  line={0.12,0.14,0.18,1},
  aqua={0.10,0.85,0.90,1},
  text={0.90,0.92,0.96,1},
  heirloom={0.00,0.80,1.00,1},
}
local function solid(parent,layer,r,g,b,a)
  local tx=parent:CreateTexture(nil,layer)
  tx:SetTexture("Interface\\Buttons\\WHITE8X8")
  tx:SetVertexColor(r,g,b,a)
  tx:SetAllPoints(parent)
  return tx
end
local function border(parent,layer,r,g,b,a,th)
  th=th or 1
  local t=parent:CreateTexture(nil,layer)
  local btm=parent:CreateTexture(nil,layer)
  local l=parent:CreateTexture(nil,layer)
  local rtx=parent:CreateTexture(nil,layer)
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  btm:SetTexture("Interface\\Buttons\\WHITE8X8")
  l:SetTexture("Interface\\Buttons\\WHITE8X8")
  rtx:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(r,g,b,a)
  btm:SetVertexColor(r,g,b,a)
  l:SetVertexColor(r,g,b,a)
  rtx:SetVertexColor(r,g,b,a)
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0)
  t:SetPoint("TOPRIGHT",parent,"TOPRIGHT",0,0)
  t:SetHeight(th)
  btm:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",0,0)
  btm:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",0,0)
  btm:SetHeight(th)
  l:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0)
  l:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",0,0)
  l:SetWidth(th)
  rtx:SetPoint("TOPRIGHT",parent,"TOPRIGHT",0,0)
  rtx:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",0,0)
  rtx:SetWidth(th)
  return {t,btm,l,rtx}
end
function T:ApplyPanel(f,kind)
  local c=self.c
  local col=c.panel
  if kind=="navy" then col=c.navy end
  solid(f,"BACKGROUND",col[1],col[2],col[3],col[4])
  border(f,"BORDER",c.line[1],c.line[2],c.line[3],c.line[4],1)
end
function T:ApplyButton(btn)
  local c=self.c
  btn._bg=btn:CreateTexture(nil,"BACKGROUND")
  btn._bg:SetAllPoints(btn)
  btn._bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  btn._bg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.9)
  border(btn,"BORDER",c.line[1],c.line[2],c.line[3],c.line[4],1)
  btn:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
  local ht=btn:GetHighlightTexture()
  if ht then ht:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.18) end
  btn:SetScript("OnEnter",function()
    btn._bg:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.22)
  end)
  btn:SetScript("OnLeave",function()
    btn._bg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.9)
  end)
end
function T:Font(parent,size,outline)
  local fs=parent:CreateFontString(nil,"OVERLAY")
  fs:SetFont(STANDARD_TEXT_FONT,size or 12,outline or "")
  fs:SetTextColor(self.c.text[1],self.c.text[2],self.c.text[3],self.c.text[4])
  fs:SetJustifyH("LEFT")
  return fs
end

function T:ApplyScrollBar(sb)
  if not sb or sb._eaSkinned then return end
  sb._eaSkinned=true
  local c=self.c
  local up=_G[sb:GetName().."ScrollUpButton"]
  local dn=_G[sb:GetName().."ScrollDownButton"]
  if up then up:Hide() up:SetAlpha(0) up:EnableMouse(false) end
  if dn then dn:Hide() dn:SetAlpha(0) dn:EnableMouse(false) end
  sb:SetWidth(12)
  if sb.SetThumbTexture then sb:SetThumbTexture("Interface\\Buttons\\WHITE8X8") end
  local thumb=(sb.GetThumbTexture and sb:GetThumbTexture()) or _G[sb:GetName().."ThumbTexture"]
  if thumb then
    thumb:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.78)
    thumb:SetHeight(30)
  end
  local bg=sb:CreateTexture(nil,"BACKGROUND")
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetVertexColor(c.navy[1],c.navy[2],c.navy[3],0.65)
  bg:SetPoint("TOPLEFT",sb,"TOPLEFT",0,0)
  bg:SetPoint("BOTTOMRIGHT",sb,"BOTTOMRIGHT",0,0)
  border(sb,"BORDER",c.line[1],c.line[2],c.line[3],0.85,1)
  sb:SetScript("OnEnter",function() if thumb then thumb:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.95) end end)
  sb:SetScript("OnLeave",function() if thumb then thumb:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.78) end end)
end