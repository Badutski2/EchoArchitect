local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
local UI=EA.UI
local Win=UI.Window
local W=UI.Widgets
local T=UI.Theme
local Page=CreateFrame("Frame",nil,UIParent)
T:ApplyPanel(Page,"bg")

local function sectionText()
  return {
    weights=[[
|cff00ffffEchoArchitect|r makes decisions based on a weight system.
Every Echo has a value. Every quality can modify that value.

The addon always compares total calculated weight when choosing between:
• Picking
• Rerolling
• Banishing
Higher weight = higher priority.

|cff00ffffUnderstanding Weights|r
Each Echo can have:
• A base weight
• A quality bonus
• A quality multiplier

Final Value =
(Base Weight + Bonus) × Multiplier

Weights represent preference, not promise.

|cff00ffffQuality Bonus & Multiplier|r
Bonus adds flat value.
Multiplier scales the total weight.

Use Quality Weighting when:
• You slightly prefer higher rarity.
• Weighting is generalized.

|cff00ffffWhat Buckets Do|r
Buckets prevent over-stacking similar effects.
Example:
You create a bucket called |cff00ff00Hit Rating|r.
You add |cff00ffffKeen Aim|r to that bucket.
If Keen Aim appears multiple times:
The bucket tracks how many “Hit Rating” effects you already have.
You can then:
• Reduce weight after X stacks
• Prevent excessive stacking

|cffffcc00Why Buckets Matter|r
Without Buckets:
Automation may overvalue repeated stats, as for example, Keen Aim does not have it's weight reduced for each instance of it.
This could lead to over valuing Hit Rating even though you have reached the Hit cap.

|cff00ff00Best Practice|r
• Keep weights logical.
• Use Buckets for specific categories.
• Avoid extreme values unless intentional.
]],

    profiles=[[
Profiles store your complete |cff00ffffEchoArchitect|r configuration.
A profile includes:
• All Echo weights
• Bucket assignments
• Quality bonuses and multipliers
• Automation settings

|cff00ffffWhy Use Profiles?|r
Profiles allow you to:
• Separate builds for the same class
• Share setups with other players
• Quickly swap Weights for different purposes

|cff00ffffSwitching Profiles|r
Switching profiles:
• Immediately applies new weights
• Updates automation behavior
• Changes bucket logic

Do not switch mid-session unless intentional.

|cff00ffffGood Profile Habits|r
• Keep one stable “Main” profile.
• Create test profiles for experimentation.
• Export before major adjustments.
• Rename clearly to avoid confusion.

|cff00ff00Friendly Tip|r
If behavior feels inconsistent,
verify the active profile before adjusting weights.
Most confusion comes from editing the wrong profile.

Share your Profiles on the Ebonhold Discord for other players!
]],

    impex=[[
Profiles can be shared via export strings.
This allows:
• Backup of your configuration
• Sharing builds with friends
• Transferring setups between characters

|cffff0000IMPORTANT WARNING|r
|cffff8800When importing or exporting large logbook databases,
the game may freeze temporarily.|r

This is normal behavior.
Do NOT:
• Force close the game
• Alt+F4
• Reload UI repeatedly
Wait until the operation completes.

|cff00ffffBefore Importing|r
• Ensure you are on the correct profile.
• Backup your current profile.
• Confirm the string source is trusted.

|cff00ffffAfter Importing|r
• Review weights and buckets.
• Verify automation settings.
• Run a short test session.

|cff00ffffWhy Importing / Exporting Matters|r
Eventually, we'll be able to build a singular database for quality chances per level and chances per echo.
]],

    settings=[[
|cffffcc00Understanding the Settings Page|r
The Settings page controls how |cff00ffffEchoArchitect|r behaves during a session.
Every option here directly affects:
• Automation decisions  
• Reroll behavior  
• Safety pauses  
• Visual display  
Think of this page as the engine control panel.

|cffffcc00Live Session Impact|r
Changes to Settings apply immediately during a session.
Be mindful when adjusting:
• Threshold values  
• Reroll aggressiveness  
• Automation speed  
Sudden changes can alter decision behavior instantly.
Consider only tuning settings while either preparing for a session, or after a session has ended.

|cff00ffffAutomation Toggles|r  
These determine whether |cff00ffffEchoArchitect|r:
• Automatically picks Echoes  
• Automatically rerolls  
• Automatically banishes  
• Or simply advises without acting  
If disabled, the addon will observe but not intervene.

|cff00ffffSafety Rules|r  
These are protective systems that pause automation to prevent:
• Picking low-value Echoes  
• Over-stacking duplicates  
• Acting when multiple strong options exist  
Safety rules are highly recommended for stable sessions.

|cff00ffffUI Behavior|r  
Controls visual and interface-related features such as:
• UI Scale  
• Tooltip modes  
• Start/Stop button display  
• Remaining counters visibility  

|cff00ff00Scale Gradually|r  
Once your Weights and Buckets are well-tuned:
• Increase reroll aggressiveness  
• Raise threshold values  
• Enable stronger automation options  

|cffffcc00Important Advice|r
If something feels “too aggressive”:
• Lower the Echo weights  
• Adjust Quality multipliers  
• Refine Buckets  

Avoid hard-blacklisting everything as it reduces flexibility.
Automation amplifies your logic, it does not replace it.
]],

    support=[[
|cff00ffffEchoArchitect|r is designed to be:
• Stable
• Predictable
• Logic-driven
• Single session focused

|cff00ffffWhat It Is Designed For|r
• Automated Echo optimization
• Structured weight-based decision making
• Controlled reroll behavior

|cff00ffffWhat It Is NOT|r
• A random Echo picker
• A guaranteed “best build” generator
• A replacement for build knowledge
It enhances your logic, it does not replace it.

|cff00ffffWhen Suggesting a Feature|r
Please include:
• The goal of the feature
• Where it should appear in the UI
• How it should behave in edge cases
• What problem it solves

|cff00ffffWhen Reporting a Bug|r
Include:
• The exact error message
• What you were doing before it happened
• When exactly it occurred
• Potential steps to reproduce

|cffffcc00Contact & Support|r
For feedback, bug reports, or feature requests:
Contact James on Discord:
|cff00ffffbadutski2|r
]]
  }
end

local sections=sectionText()
local current="weights"

local top=CreateFrame("Frame",nil,Page)
top:SetPoint("TOPLEFT",Page,"TOPLEFT",10,-10)
top:SetPoint("TOPRIGHT",Page,"TOPRIGHT",-10,-10)
top:SetHeight(34)

local btns={}
local defs={
  {id="weights",label="Echo Weights & Buckets"},
  {id="profiles",label="Profile Information"},
  {id="impex",label="Importing and Exporting"},
  {id="settings",label="Settings Explained"},
  {id="support",label="Support & Features"},
}
local function styleButton(b,sel)
  if sel then
    if b.LockHighlight then b:LockHighlight() end
    if b._sel then b._sel:Show() end
  else
    if b.UnlockHighlight then b:UnlockHighlight() end
    if b._sel then b._sel:Hide() end
  end
end

local btnOrder={}
for i=1,#defs do
  local d=defs[i]
  local b=W:Button(top,d.label,150,26,function()
    Page:Select(d.id)
  end)
  b._sel=b:CreateTexture(nil,"ARTWORK")
  b._sel:SetAllPoints(b)
  b._sel:SetTexture("Interface\Buttons\WHITE8X8")
  b._sel:SetVertexColor(0.10,0.35,0.55,0.35)
  b._sel:Hide()
  btns[d.id]=b
  btnOrder[i]=b
end

function Page:Layout()
  local w=top:GetWidth() or 0
  if w<200 then
    local x=0
    for i=1,#btnOrder do
      local b=btnOrder[i]
      b:ClearAllPoints()
      b:SetPoint("LEFT",top,"LEFT",x,0)
      b:SetWidth(150)
      x=x+156
    end
    return
  end
  local gap=6
  local n=#btnOrder
  local bw=math.floor((w-(gap*(n-1)))/n)
  local x=0
  for i=1,n do
    local b=btnOrder[i]
    b:ClearAllPoints()
    b:SetPoint("LEFT",top,"LEFT",x,0)
    b:SetWidth(bw)
    x=x+bw+gap
  end
end

local body=CreateFrame("Frame",nil,Page)
body:SetPoint("TOPLEFT",top,"BOTTOMLEFT",0,-10)
body:SetPoint("BOTTOMRIGHT",Page,"BOTTOMRIGHT",-10,10)

local sf=CreateFrame("ScrollFrame","EchoArchitectHelpScroll",body,"UIPanelScrollFrameTemplate")
sf:SetPoint("TOPLEFT",body,"TOPLEFT",0,0)
sf:SetPoint("BOTTOMRIGHT",body,"BOTTOMRIGHT",0,0)
local sb=_G[sf:GetName().."ScrollBar"]
if sb then T:ApplyScrollBar(sb) end

local content=CreateFrame("Frame",nil,sf)
content:SetPoint("TOPLEFT",sf,"TOPLEFT",0,0)
content:SetPoint("TOPRIGHT",sf,"TOPRIGHT",0,0)
sf:SetScrollChild(content)

local text=T:Font(content,13,"")
text:SetPoint("TOPLEFT",content,"TOPLEFT",6,-6)
text:SetPoint("TOPRIGHT",content,"TOPRIGHT",-26,-6)
text:SetJustifyH("LEFT")
text:SetJustifyV("TOP")

local warnBg=CreateTexture and content:CreateTexture(nil,"BACKGROUND") or nil
if warnBg then
  warnBg:SetTexture("Interface\Buttons\WHITE8X8")
  warnBg:SetVertexColor(0.45,0.12,0.12,0.45)
  warnBg:Hide()
end

function Page:Update()
  for id,b in pairs(btns) do
    styleButton(b,id==current)
  end
  local t=sections[current] or ""
  text:SetText(t)
  local w=body:GetWidth() or 0
  local tw
  if w<200 then tw=460 else tw=w-40 end
  if tw<200 then tw=460 end
  text:SetWidth(tw)
  local h=(text:GetStringHeight() or 0)+20
  if h<1 then h=1 end
  content:SetHeight(h)
  if current=="impex" and warnBg then
    warnBg:Show()
    warnBg:ClearAllPoints()
    warnBg:SetPoint("TOPLEFT",content,"TOPLEFT",0,0)
    warnBg:SetPoint("TOPRIGHT",content,"TOPRIGHT",0,0)
    local block=160
    warnBg:SetHeight(block)
  elseif warnBg then
    warnBg:Hide()
  end
end

function Page:Select(id)
  if id and sections[id] then current=id end
  self:Layout()
  self:Update()
  if sf and sf.SetVerticalScroll then sf:SetVerticalScroll(0) end
end

local function ensureWidth()
  local bw=body:GetWidth() or 0
  if bw<200 then
    local pw=Page:GetWidth() or 0
    if pw>240 then bw=pw-20 end
  end
  if bw<200 then bw=600 end
  content:SetWidth(bw)
end

local oldUpdate=Page.Update
function Page:Update()
  ensureWidth()
  oldUpdate(self)
end

Page:SetScript("OnShow",function()
  Page:Select("weights")
end)

body:SetScript("OnSizeChanged",function()
  if Page:IsShown() then
    Page:Layout()
    Page:Update()
  end
end)

top:SetScript("OnSizeChanged",function()
  if Page:IsShown() then
    Page:Layout()
  end
end)

Win:RegisterPage("help",Page)
