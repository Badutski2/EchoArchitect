local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
local f=CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
local function onLoaded()
  EA.Profiles:Init()
  EA.Logbook:Init()
  if EA.DB and EA.DB.WarmSpellCache then EA.DB:WarmSpellCache() end
  if EA.Run and EA.Run.TrackLevelOne then EA.Run:TrackLevelOne() end
  if EA.Run and EA.Run.MaybeReset then EA.Run:MaybeReset() end
  if EA.Run and EA.Run.SyncSessionToCurrentLevel then EA.Run:SyncSessionToCurrentLevel() end
  EA.Engine:StartTicker()
  EA.UI.Window:Create()
  EA.UI.StartStop:Create()
  local db=EchoArchitect_CharDB
  if db then
    db.ui=db.ui or {}
    db.ui.window=db.ui.window or {}
    db.ui.window.shown=false
  end
  local tab=db and db.ui and db.ui.window and db.ui.window.tab or "dashboard"
  EA.UI.Window:ShowTab(tab)
  EA.UI.Window.frame:Hide()
  local panel=CreateFrame("Frame")
  panel.name="EchoArchitect"
  panel:Hide()
  panel:SetScript("OnShow",function()
    if GameMenuFrame and GameMenuFrame:IsShown() then HideUIPanel(GameMenuFrame) end
    if InterfaceOptionsFrame then InterfaceOptionsFrame:Hide() end
    local f=EA.UI and EA.UI.Window and EA.UI.Window.frame
    if f and not f:IsShown() then
      EA.UI.Window:Toggle()
    end
  end)
  if type(InterfaceOptions_AddCategory)=="function" then
    InterfaceOptions_AddCategory(panel)
  end
end
f:SetScript("OnEvent",function(_,ev,arg1,arg2,arg3,arg4,arg5)
  if ev=="ADDON_LOADED" and arg1==addonName then
    onLoaded()
  elseif ev=="PLAYER_LOGIN" then
    EA.Engine:SetEnabled(false)
    if EA.Run and EA.Run.TrackLevelOne then EA.Run:TrackLevelOne() end
    if EA.Run and EA.Run.SyncSessionToCurrentLevel then EA.Run:SyncSessionToCurrentLevel() end
    local sent=false
    local t=0
    local tf=CreateFrame("Frame")
    tf:SetScript("OnUpdate",function(_,el)
      if sent then return end
      t=t+(tonumber(el) or 0)
      if t>=2 then
        sent=true
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
          DEFAULT_CHAT_FRAME:AddMessage("|cff7fd6e8EchoArchitect Enabled|r - Use |cffffffff/ea|r to configure")
        end
        tf:SetScript("OnUpdate",nil)
      end
    end)
  elseif ev=="PLAYER_LEVEL_UP" then
    if EA.Run and EA.Run.TrackLevelOne then EA.Run:TrackLevelOne() end
    if EA.Run and EA.Run.MaybeReset then EA.Run:MaybeReset() end
    if EA.Run and EA.Run.OnLevelUp then EA.Run:OnLevelUp(tonumber(arg1) or 0) end
  elseif ev=="PLAYER_XP_UPDATE" then
    if EA.Run and EA.Run.OnXPUpdate then EA.Run:OnXPUpdate() end
  elseif ev=="PLAYER_ENTERING_WORLD" then
    if EA.Run and EA.Run.TrackLevelOne then EA.Run:TrackLevelOne() end
    if EA.Run and EA.Run.SyncSessionToCurrentLevel then EA.Run:SyncSessionToCurrentLevel() end
  elseif ev=="UNIT_SPELLCAST_SUCCEEDED" then
    if arg1~="player" then return end
    local _,class=UnitClass("player")
    if class=="ROGUE" then return end
    if arg2=="Shadowstep" then
      if EA.Run and EA.Run.OnShadowstepCast then EA.Run:OnShadowstepCast() end
    end
  end
end)
SLASH_ECHOARCHITECT1="/ea"
SlashCmdList["ECHOARCHITECT"]=function(msg)
  EA.UI.Window:Toggle()
end