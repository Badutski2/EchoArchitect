local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.Stats=EA.Stats or {}
local S=EA.Stats
local scan=CreateFrame("GameTooltip","EchoArchitectScanTooltip",UIParent,"GameTooltipTemplate")
scan:SetOwner(UIParent,"ANCHOR_NONE")
local statKeys={
  STR=true,AGI=true,STA=true,INT=true,SPI=true,
  AP=true,SP=true,CRIT=true,HASTE=true,HIT=true,
  ARMOR=true,RESIL=true,
}
local function add(dst,k,v)
  if not k or not v then return end
  dst[k]=(tonumber(dst[k]) or 0)+(tonumber(v) or 0)
end
local function parseLine(line,dst)
  if not line or line=="" then return end
  local n
  n=string.match(line,"%+%s*(%d+)%s+Strength") if n then add(dst,"STR",n) end
  n=string.match(line,"%+%s*(%d+)%s+Agility") if n then add(dst,"AGI",n) end
  n=string.match(line,"%+%s*(%d+)%s+Stamina") if n then add(dst,"STA",n) end
  n=string.match(line,"%+%s*(%d+)%s+Intellect") if n then add(dst,"INT",n) end
  n=string.match(line,"%+%s*(%d+)%s+Spirit") if n then add(dst,"SPI",n) end
  n=string.match(line,"%+%s*(%d+)%s+Attack Power") if n then add(dst,"AP",n) end
  n=string.match(line,"%+%s*(%d+)%s+Spell Power") if n then add(dst,"SP",n) end
  n=string.match(line,"%+%s*(%d+)%s+Armor") if n then add(dst,"ARMOR",n) end
  n=string.match(line,"%+%s*(%d+)%s+Resilience") if n then add(dst,"RESIL",n) end
  n=string.match(line,"(%d+)%s*%%.*critical") if n then add(dst,"CRIT",n) end
  n=string.match(line,"(%d+)%s*%%.*haste") if n then add(dst,"HASTE",n) end
  n=string.match(line,"(%d+)%s*%%.*hit") if n then add(dst,"HIT",n) end
end
function S:SpellStatContribution(spellId)
  local out={}
  if not spellId or spellId==0 then return out end
  scan:ClearLines()
  scan:SetSpellByID(spellId)
  for i=2,scan:NumLines() do
    local fs=_G["EchoArchitectScanTooltipTextLeft"..i]
    local t=fs and fs:GetText()
    parseLine(t,out)
  end
  return out
end
function S:GetAshTreeSpellsAndRanks()
  local out={}
  local st=ProjectEbonhold and ProjectEbonhold.SkillTree
  if not st then return out end
  local data=st.LoadoutsData
  if type(data)~="table" then return out end
  local sel=tonumber(data.selectedLoadoutId or 0) or 0
  local loadouts=data.loadouts
  if type(loadouts)~="table" then return out end
  local active=nil
  for i=1,#loadouts do
    if tonumber(loadouts[i].id or 0)==sel then active=loadouts[i] break end
  end
  if not active then return out end
  local ranks=active.nodeRanks
  if type(ranks)~="table" then return out end
  if type(TalentDatabase)~="table" then return out end
  local tree=TalentDatabase[0]
  if not tree or type(tree.nodes)~="table" then return out end
  local byId={}
  for i=1,#tree.nodes do byId[tree.nodes[i].id]=tree.nodes[i] end
  for nodeId,rank in pairs(ranks) do
    rank=tonumber(rank or 0) or 0
    if rank>0 then
      local node=byId[nodeId]
      if node and type(node.spells)=="table" then
        local sid=node.spells[math.min(rank,#node.spells)] or node.spells[1]
        if sid then out[#out+1]={spellId=tonumber(sid) or 0,rank=rank} end
      end
    end
  end
  return out
end
function S:Compute()
  local pr=EA.Profiles:GetActiveProfile()
  local baseline=pr and pr.stats and pr.stats.gearBaseline or {}
  local extra={}
  local eff={}
  for k,v in pairs(baseline) do if statKeys[k] then eff[k]=tonumber(v) or 0 end end
  local perkStats={}
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.GetGrantedPerks then
    local ok,granted=pcall(ProjectEbonhold.PerkService.GetGrantedPerks)
    if ok and type(granted)=="table" then
      for name,list in pairs(granted) do
        if type(list)=="table" and list[1] and list[1].spellId then
          local sid=tonumber(list[1].spellId) or 0
          local stacks=#list
          if sid>0 and stacks>0 then
            local contrib=self:SpellStatContribution(sid)
            for k,v in pairs(contrib) do add(perkStats,k,(tonumber(v) or 0)*stacks) end
          end
        end
      end
    end
  end
  for k,v in pairs(perkStats) do add(eff,k,v) end
  local ashStats={}
  local ash=self:GetAshTreeSpellsAndRanks()
  for i=1,#ash do
    local sid=ash[i].spellId
    if sid and sid>0 then
      local contrib=self:SpellStatContribution(sid)
      for k,v in pairs(contrib) do add(ashStats,k,v) end
    end
  end
  for k,v in pairs(ashStats) do add(eff,k,v) end
  return {effective=eff,baseline=baseline,extra=extra,echo=perkStats,ash=ashStats}
end
