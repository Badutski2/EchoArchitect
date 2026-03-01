local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.UI=EA.UI or {}
local UI=EA.UI
UI.Widgets=UI.Widgets or {}
local W=UI.Widgets
local T=UI.Theme
function W:Button(parent,text,w,h,onclick)
  local b=CreateFrame("Button",nil,parent)
  b:SetWidth(w or 120)
  b:SetHeight(h or 22)
  T:ApplyButton(b)
  local fs=T:Font(b,12,"")
  fs:SetPoint("CENTER",b,"CENTER",0,0)
  fs:SetText(text or "")
	b._label=fs
	b._fs=fs
  function b:SetText(t) self._label:SetText(t or "") end
  function b:GetText() return self._label:GetText() end
  if onclick then b:SetScript("OnClick",onclick) end
  return b
end
function W:Label(parent,text,size)
  local fs=T:Font(parent,size or 12,"")
  fs:SetText(text or "")
  return fs
end
function W:EditBox(parent,w,h)
  local e=CreateFrame("EditBox",nil,parent)
  e:SetWidth(w or 90)
  e:SetHeight(h or 20)
  e:SetFont(STANDARD_TEXT_FONT,12,"")
  e:SetAutoFocus(false)
  e:SetTextInsets(6,6,3,3)
  local bg=e:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(e)
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetVertexColor(0.03,0.04,0.06,0.95)
  local c=UI.Theme.c
  local t=parent:CreateTexture(nil,"BORDER")
  t:SetTexture("Interface\\Buttons\\WHITE8X8")
  t:SetVertexColor(c.line[1],c.line[2],c.line[3],c.line[4])
  t:SetPoint("TOPLEFT",e,"TOPLEFT",-1,1)
  t:SetPoint("BOTTOMRIGHT",e,"BOTTOMRIGHT",1,-1)
  e._border=t
  e:SetScript("OnEscapePressed",function() e:ClearFocus() end)
  e:SetScript("OnEnterPressed",function() e:ClearFocus() end)
  return e
end

function W:MultiLineEditBox(parent,w,h)
  W._mlId=(tonumber(W._mlId or 0) or 0)+1
  local nm="EchoArchitectMLScroll"..tostring(W._mlId)
  local sf=CreateFrame("ScrollFrame",nm,parent,"UIPanelScrollFrameTemplate")
  sf:SetWidth(w or 360)
  sf:SetHeight(h or 160)
  local eb=CreateFrame("EditBox",nil,sf)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetFont(STANDARD_TEXT_FONT,12,"")
  eb:SetWidth((w or 360)-28)
  eb:SetHeight(h or 160)
  eb:SetTextInsets(6,6,6,6)
  eb:SetScript("OnEscapePressed",function() eb:ClearFocus() end)
  eb:SetScript("OnEditFocusGained",function() eb:HighlightText() end)
  eb:SetScript("OnEditFocusLost",function() eb:HighlightText(0,0) end)
  sf:SetScrollChild(eb)
  sf._edit=eb
  local bg=sf:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(sf)
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetVertexColor(0.03,0.04,0.06,0.95)
  local c=UI.Theme.c
  local br=sf:CreateTexture(nil,"BORDER")
  br:SetTexture("Interface\\Buttons\\WHITE8X8")
  br:SetVertexColor(c.line[1],c.line[2],c.line[3],c.line[4])
  br:SetPoint("TOPLEFT",sf,"TOPLEFT",-1,1)
  br:SetPoint("BOTTOMRIGHT",sf,"BOTTOMRIGHT",1,-1)
  sf._border=br
  local sb=_G[nm.."ScrollBar"]
  if sb and T and T.ApplyScrollBar then T:ApplyScrollBar(sb) end
  return sf,eb
end
function W:BoxButton(parent,text,w,h)
  local b=CreateFrame("Button",nil,parent)
  b:SetWidth(w or 120)
  b:SetHeight(h or 20)
  T:ApplyButton(b)
  b:SetScript("OnEnter",nil)
  b:SetScript("OnLeave",nil)
  b:SetHighlightTexture(nil)
  local fs=T:Font(b,12,"")
  fs:SetPoint("CENTER",b,"CENTER",0,0)
  fs:SetText(text or "")
  b._fs=fs
  function b:SetText(t) self._fs:SetText(t or "") end
  return b
end
function W:Check(parent,text,onToggle)
  local f=CreateFrame("Frame",nil,parent)
  f:SetHeight(20)
  f:SetWidth(220)
  local b=CreateFrame("Button",nil,f)
  b:SetWidth(16) b:SetHeight(16)
  b:SetPoint("LEFT",f,"LEFT",0,0)
  b._box=b:CreateTexture(nil,"BACKGROUND")
  b._box:SetAllPoints(b)
  b._box:SetTexture("Interface\\Buttons\\WHITE8X8")
  b._box:SetVertexColor(0.03,0.04,0.06,0.95)
  local c=UI.Theme.c
  local br=b:CreateTexture(nil,"BORDER")
  br:SetAllPoints(b)
  br:SetTexture("Interface\\Buttons\\WHITE8X8")
  br:SetVertexColor(c.line[1],c.line[2],c.line[3],c.line[4])
  b._tick=b:CreateTexture(nil,"OVERLAY")
  b._tick:SetAllPoints(b)
  b._tick:SetTexture("Interface\\Buttons\\WHITE8X8")
  b._tick:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.9)
  b._tick:Hide()
  local fs=T:Font(f,12,"")
  fs:SetPoint("LEFT",b,"RIGHT",6,0)
  fs:SetText(text or "")
  f._btn=b
  f._label=fs
  f._value=false
  function f:SetValue(v)
    self._value=v and true or false
    if self._value then self._btn._tick:Show() else self._btn._tick:Hide() end
  end
  function f:GetValue() return self._value end
  b:SetScript("OnClick",function()
    f:SetValue(not f:GetValue())
    if onToggle then onToggle(f,f:GetValue()) end
  end)
  local hit=CreateFrame("Button",nil,f)
  hit:SetAllPoints(f)
  hit:RegisterForClicks("AnyUp")
  hit:SetScript("OnClick",function() b:Click() end)
  return f
end

function W:AttachSpellTooltip(frame,spellIdFunc)
  if not frame then return end
  frame:EnableMouse(true)
  frame:SetScript("OnEnter",function(self)
    local sid=spellIdFunc
    if type(spellIdFunc)=="function" then sid=spellIdFunc(self) end
    sid=tonumber(sid or 0) or 0
    if sid<=0 or not GameTooltip then return end
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
    if GameTooltip.SetHyperlink then
      GameTooltip:SetHyperlink("spell:"..tostring(sid))
    elseif GameTooltip.SetSpellByID then
      GameTooltip:SetSpellByID(sid)
    else
      local nm=GetSpellInfo and GetSpellInfo(sid)
      if nm and GameTooltip.SetText then GameTooltip:SetText(nm) end
    end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
end

function W:BindCommit(editbox,commitFn)
  if not editbox or not commitFn then return end
  local function commit()
    if editbox._eaCommitLock then return end
    editbox._eaCommitLock=true
    commitFn(editbox)
    editbox._eaCommitLock=false
  end
  editbox:SetScript("OnEnterPressed",function() commit() editbox:ClearFocus() end)
  editbox:SetScript("OnEscapePressed",function() editbox:ClearFocus() end)
  editbox:SetScript("OnEditFocusGained",function() editbox:HighlightText() end)
  editbox:SetScript("OnEditFocusLost",function() editbox:HighlightText(0,0) end)
  editbox._eaDirty=false
  editbox._eaT=0
  editbox:SetScript("OnTextChanged",function()
    if editbox._eaSetting then return end
    editbox._eaDirty=true
    editbox._eaT=0
    if editbox:HasFocus() then
      commit()
      editbox._eaDirty=false
      editbox._eaT=0
    end
  end)
  editbox:SetScript("OnUpdate",function(self,el)
    if not self._eaDirty then return end
    if self:HasFocus() then return end
    self._eaT=self._eaT+(el or 0)
    if self._eaT>=0.20 then
      self._eaDirty=false
      self._eaT=0
      commit()
    end
  end)
end

function W:Slider(parent,label,minV,maxV,step,width,onChange,formatFn)
  local f=CreateFrame("Frame",nil,parent)
  f:SetWidth(width or 240)
  f:SetHeight(44)
  local l=T:Font(f,12,"")
  l:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
  l:SetText(label or "")
  local v=T:Font(f,12,"")
  v:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
  v:SetJustifyH("RIGHT")
  local bar=CreateFrame("Frame",nil,f)
  bar:SetPoint("TOPLEFT",l,"BOTTOMLEFT",2,-8)
  bar:SetWidth((width or 240)-4)
  bar:SetHeight(14)
  local bg=bar:CreateTexture(nil,"BACKGROUND")
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetVertexColor(0.03,0.04,0.06,0.95)
  bg:SetAllPoints(bar)
  local fill=bar:CreateTexture(nil,"ARTWORK")
  fill:SetTexture("Interface\\Buttons\\WHITE8X8")
  local c=UI.Theme.c
  fill:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.35)
  fill:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0)
  fill:SetPoint("BOTTOMLEFT",bar,"BOTTOMLEFT",0,0)
  fill:SetWidth(0)
  local knob=CreateFrame("Button",nil,bar)
  knob:SetWidth(10)
  knob:SetHeight(18)
  local kt=knob:CreateTexture(nil,"OVERLAY")
  kt:SetTexture("Interface\\Buttons\\WHITE8X8")
  kt:SetVertexColor(c.aqua[1],c.aqua[2],c.aqua[3],0.9)
  kt:SetAllPoints(knob)
  local mn=tonumber(minV or 0) or 0
  local mx=tonumber(maxV or 1) or 1
  local st=tonumber(step or 0) or 0
  local val=mn
  local function snap(x)
    if st and st>0 then
      local n=math.floor((x-mn)/st+0.5)
      return mn+n*st
    end
    return x
  end
  local function clamp(x)
    if x<mn then return mn end
    if x>mx then return mx end
    return x
  end
  local function setValue(x,fire)
    x=clamp(snap(tonumber(x or 0) or 0))
    val=x
    local pct=0
    if mx>mn then pct=(val-mn)/(mx-mn) end
    if pct<0 then pct=0 elseif pct>1 then pct=1 end
    local w=(bar:GetWidth() or 0)*pct
    fill:SetWidth(w)
    knob:ClearAllPoints()
    knob:SetPoint("CENTER",bar,"LEFT",w,0)
    if formatFn then
      v:SetText(tostring(formatFn(val) or ""))
    else
      v:SetText(tostring(val))
    end
    if fire and onChange then onChange(val) end
  end
  local function setFromCursor()
    local cx,cy=GetCursorPosition()
    local sc=bar:GetEffectiveScale() or 1
    cx=cx/sc
    local x=cx-(bar:GetLeft() or 0)
    local pct=0
    local bw=bar:GetWidth() or 1
    if bw>0 then pct=x/bw end
    if pct<0 then pct=0 elseif pct>1 then pct=1 end
    setValue(mn+pct*(mx-mn),true)
  end
  f:EnableMouse(true)
  bar:EnableMouse(true)
  bar:EnableMouseWheel(true)
  knob:EnableMouse(true)
  bar:SetScript("OnMouseDown",function() f._drag=true setFromCursor() end)
  knob:SetScript("OnMouseDown",function() f._drag=true setFromCursor() end)
  bar:SetScript("OnMouseUp",function() f._drag=false end)
  knob:SetScript("OnMouseUp",function() f._drag=false end)
  f:SetScript("OnMouseUp",function() f._drag=false end)
  f:SetScript("OnHide",function() f._drag=false end)
  f:SetScript("OnUpdate",function()
    if f._drag then
      if not IsMouseButtonDown("LeftButton") then f._drag=false return end
      setFromCursor()
    end
  end)
  bar:SetScript("OnMouseWheel",function(_,d)
    local dv=st and st>0 and st or ((mx-mn)/100)
    setValue(val+(d>0 and dv or -dv),true)
  end)
  function f:SetValue(x) setValue(x,false) end
  function f:GetValue() return val end
  f._bar=bar
  f._label=l
  f._value=v
  f:SetValue(mn)
  return f
end

function W:GetSpellTooltipText(spellId)
  spellId=tonumber(spellId or 0) or 0
  if spellId<=0 or not GameTooltip then return "" end
  self._spellTipCache=self._spellTipCache or {}
  local c=self._spellTipCache[spellId]
  if c then return c end
  self._scanTip=self._scanTip or CreateFrame("GameTooltip","EchoArchitectScanTooltip",UIParent,"GameTooltipTemplate")
  local tip=self._scanTip
  tip:SetOwner(UIParent,"ANCHOR_NONE")
  tip:ClearLines()
  if tip.SetHyperlink then tip:SetHyperlink("spell:"..tostring(spellId)) elseif tip.SetSpellByID then tip:SetSpellByID(spellId) end
  local out=""
  for i=1,30 do
    local fs=_G[tip:GetName().."TextLeft"..i]
    if not fs then break end
    local t=fs:GetText()
    if t and t~="" then out=out.." "..t end
  end
  out=string.lower(out or "")
  tip:Hide()
  self._spellTipCache[spellId]=out
  return out
end

return W
