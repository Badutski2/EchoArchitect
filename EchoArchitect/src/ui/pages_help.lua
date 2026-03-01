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
Echo Weights & Buckets

EchoArchitect decides which Echo to take by giving every Echo a score. The score is based on its Weight, its Quality, and whether it belongs to a Bucket with Stacks.

Weights
- Every Echo in the library has a Weight per Quality (Common/Uncommon/Rare/etc).
- Higher Weight means the Echo is preferred more often.
- Weight 0 means neutral (it can still be picked if nothing better exists).
- Negative Weight means the Echo is actively avoided and will only be picked if your rules force it.

Quality
- Quality is the game’s roll for that Echo (Common, Uncommon, Rare, etc).
- Each quality is tracked separately in the library, so you can prefer a Rare version and dislike a Common version of the same Echo.

Buckets
Buckets let you group Echoes that “compete” with each other by limiting how many of that group can be taken.

Example
- Bucket: "Movement"
- Echoes: Sprint Echo, Dash Echo, etc
- Max Stacks: 1
This means you can only take one total from that bucket.

How Buckets work
- You assign Echo entries (spell + quality) to a bucket from the library list.
- Buckets have Max Stacks.
- If the bucket is at max stacks, EchoArchitect treats additional bucket echoes as blocked and will avoid picking them.

Why use Buckets
- Prevent stacking too many similar effects.
- Force variety across a run.
- Keep the optimizer from repeatedly grabbing "fine but redundant" bonuses.

Tips
- Start with buckets for large categories: Defense, Mobility, Utility, Single Target, AoE.
- Use low stacks (1–2) for "unique utility" buckets.
- Use higher stacks for "core scaling" buckets if you truly want them to stack.

]],

    profiles=[[
Profile Information

A Profile contains everything that affects decision-making:
- Your Echo Library weights (per spell + quality)
- Your bucket definitions (name, max stacks, and which echoes belong)
- Any per-profile preferences that influence picks and rerolls

Active Profile
- The Active Profile is what EchoArchitect uses right now.
- Switching profiles instantly changes which weights/buckets are in effect.

Why multiple profiles help
- Different specs/roles: Tank vs DPS vs Healer
- Different play styles: Speedrun vs Safe
- Different characters with different goals

What is NOT a Profile
- Session logbook history is tracked separately.
- Per-character UI placement/scale is stored separately.

Recommended workflow
1) Create a base profile (balanced).
2) Duplicate it into specialized profiles.
3) Adjust weights/buckets in the specialized ones.
4) Swap profiles when you change goals.

]],

    impex=[[
Importing and Exporting

IMPORTANT WARNING
When Importing or Exporting Profiles, the game can freeze or hitch for a while. This is normal. Do NOT force close WoW. Wait until it finishes.

Why it can freeze
- Profiles can contain a lot of data (many echoes, many buckets).
- The game has to serialize or deserialize that data inside the UI thread.
- Large strings and table rebuilds can stall the client briefly.

Best practices
- Do imports/exports in a safe location (not mid-combat).
- Avoid spamming the import button if the UI seems stuck.
- If you are exporting a large profile, give it time.

What gets exported
- Profile weights for each Echo + quality
- Bucket definitions, including max stacks and assigned echoes
- Any profile-level settings that affect decisions

What does not get exported
- Session history/logbook data
- Per-character UI placement and scale

If an import fails
- Double check you copied the whole string.
- Make sure it is from the same addon version family.
- Try reloading the UI and importing again.

]],

    settings=[[
Settings Explained

The Settings page controls how EchoArchitect behaves during a session.

Common concepts
- Automation toggles: whether EchoArchitect should auto-pick, auto-reroll, or just advise.
- Safety rules: conditions that pause automation to prevent bad states.
- UI behavior: window scale, tooltip modes, and display options.

Typical setup
- Start with conservative automation.
- Enable stronger automation only after you trust your weights/buckets.
- If something feels “too aggressive”, lower weights instead of hard blacklisting everything.

If a setting seems unclear
- Look at what it changes in the live session.
- Use a small test run and compare behavior with the setting on/off.

]],

    support=[[
Support & Features

What EchoArchitect is for
- Track and optimize Echo picks over a session.
- Let you build a preference model (weights) per Echo and per quality.
- Prevent over-stacking via Buckets.
- Keep a clear record in History/Logbook.

If you want a feature
- Describe the goal (what you want the addon to accomplish).
- Include where it should appear in the UI.
- Include examples of how it should behave in edge cases.

If something breaks
- Provide the exact error message from the WoW error frame.
- Tell what you clicked just before it happened.
- Include whether it was after an import, profile switch, or a reload.

Quality-of-life ideas that fit well
- More filters/searching in the library
- Better preset profiles
- More session summaries

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
  {id="weights",label="Echo Weights & Bucket"},
  {id="profiles",label="Profile Information"},
  {id="impex",label="Importing and Exporting"},
  {id="settings",label="Settings Explained"},
  {id="support",label="Support & Features"},
}
local function styleButton(b,sel)
  if sel then
    b._bg:SetVertexColor(0.10,0.35,0.55,0.45)
  else
    b._bg:SetVertexColor(0,0,0,0)
  end
end

local btnOrder={}
for i=1,#defs do
  local d=defs[i]
  local b=W:Button(top,d.label,150,26,function()
    current=d.id
    Page:Update()
  end)
  b._bg=b:CreateTexture(nil,"BACKGROUND")
  b._bg:SetAllPoints(b)
  b._bg:SetTexture("Interface\ChatFrame\ChatFrameBackground")
  b._bg:SetVertexColor(0,0,0,0)
  btns[d.id]=b
  btnOrder[i]=b
end

function Page:Layout()
  local w=top:GetWidth() or 0
  if w<200 then return end
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

local text=T:Font(content,12,"")
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
  if w<200 then w=500 end
  text:SetWidth(w-40)
  text:SetHeight(1)
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

Page:SetScript("OnShow",function() Page:Layout() Page:Update() end)
Page:SetScript("OnSizeChanged",function() if Page:IsShown() then Page:Layout() Page:Update() end end)

Win:RegisterPage("help",Page)
