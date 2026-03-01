local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.DB=EA.DB or {}
local DB=EA.DB
DB.CLASS_COLORS={
  WARRIOR="C79C6E",
  PALADIN="F58CBA",
  HUNTER="ABD473",
  ROGUE="FFF569",
  PRIEST="FFFFFF",
  DEATHKNIGHT="C41F3B",
  SHAMAN="0070DE",
  MAGE="69CCF0",
  WARLOCK="9482C9",
  DRUID="FF7D0A"
}
DB.ALL_CLASS_MASK=1535
DB.CLASS_PRETTY={WARRIOR="Warrior",PALADIN="Paladin",HUNTER="Hunter",ROGUE="Rogue",PRIEST="Priest",DEATHKNIGHT="Death Knight",SHAMAN="Shaman",MAGE="Mage",WARLOCK="Warlock",DRUID="Druid"}
function DB:ClassPrettyName(class)
  return self.CLASS_PRETTY[class] or (class and tostring(class) or "")
end
function DB:ClassColorCode(class)
  if not class then return "|cffffffff" end
  local c=self.CLASS_COLORS[class]
  if not c then return "|cffffffff" end
  return "|cff"..c
end
local perkdb=EchoArchitect_PerkDB or {}
local function pow2(n)
  return 2^(n or 0)
end
DB._knownSpells=nil
function DB:RebuildKnownSpells()
  local knownIds={}
  local knownNames={}
  local book=BOOKTYPE_SPELL or "spell"
  if type(GetNumSpellTabs)~="function" or type(GetSpellTabInfo)~="function" or type(GetSpellName)~="function" then
    self._knownSpells={ids=knownIds,names=knownNames}
    return
  end
  local tabs=GetNumSpellTabs() or 0
  for t=1,tabs do
    local _,_,offset,num=GetSpellTabInfo(t)
    offset=tonumber(offset or 0) or 0
    num=tonumber(num or 0) or 0
    for i=offset+1,offset+num do
      local n=GetSpellName(i,book)
      if n then
        knownNames[n]=true
        if type(GetSpellLink)=="function" then
          local link=GetSpellLink(i,book)
          if link then
            local sid=tonumber(string.match(link,"spell:(%d+)"))
            if sid then knownIds[sid]=true end
          end
        end
      end
    end
  end
  self._knownSpells={ids=knownIds,names=knownNames}
end
function DB:GetPlayerClassBit()
  local _,token,id=UnitClass("player")
  if id then return pow2(id-1) end
  if token then
    local map={WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,DEATHKNIGHT=6,SHAMAN=7,MAGE=8,WARLOCK=9,DRUID=11}
    local mid=map[token]
    if mid then return pow2(mid-1) end
  end
  return 0
end
function DB:ClassMaskAllows(mask)
  local b=self:GetPlayerClassBit()
  mask=tonumber(mask or 0) or 0
  if mask==0 then return true end
  if b==0 then return false end
  if bit and bit.band then
    return bit.band(mask,b)~=0
  end
  return math.floor(mask/b)%2==1
end
function DB:HasRequiredSpell(spellId)
  if not spellId or spellId==0 then return true end
  if self._knownSpells==nil then self:RebuildKnownSpells() end
  local sid=tonumber(spellId) or 0
  if self._knownSpells.ids and self._knownSpells.ids[sid] then return true end
  if type(GetSpellInfo)=="function" and self._knownSpells.names then
    local n=GetSpellInfo(sid)
    if n and self._knownSpells.names[n] then return true end
  end
  return false
end
local function qcolor(q)
  if q==0 then return "|cffffffff" end
  if q==1 then return "|cff1eff00" end
  if q==2 then return "|cff0070dd" end
  if q==3 then return "|cffa335ee" end
  if q==4 then return "|cffff8000" end
  return "|cffffffff"
end
function DB:QualityColor(q)
  return qcolor(tonumber(q or 0) or 0)
end
function DB:MakeKey(spellId,quality)
  return tostring(tonumber(spellId or 0) or 0)..":"..tostring(tonumber(quality or 0) or 0)
end
function DB:GetPerkMeta(spellId)
  return perkdb[tonumber(spellId or 0) or 0]
end

function DB:WarmSpellCache()
  if type(GetSpellInfo)~="function" then return end
  for sid,meta in pairs(perkdb) do
    GetSpellInfo(sid)
    local rs=tonumber(meta and meta.requiredSpell or 0) or 0
    if rs>0 then GetSpellInfo(rs) end
  end
end
function DB:IterPerks(showAll)
  local out={}
  for sid,meta in pairs(perkdb) do
    local ok=true
    if not showAll then
      ok=self:ClassMaskAllows(tonumber(meta.classMask or 0) or 0)
    end
    if ok and (not showAll) then
      ok=self:HasRequiredSpell(tonumber(meta.requiredSpell or 0) or 0)
    end
    if ok then
      local name,_,icon=GetSpellInfo(sid)
      out[#out+1]={
        spellId=sid,
        name=name or ("Spell "..tostring(sid)),
        icon=icon,
        quality=tonumber(meta.quality or 0) or 0,
        maxStack=tonumber(meta.maxStack or 0) or 0,
        classMask=tonumber(meta.classMask or 0) or 0,
        requiredSpell=tonumber(meta.requiredSpell or 0) or 0,
      }
    end
  end
  table.sort(out,function(a,b)
    if a.quality~=b.quality then return a.quality>b.quality end
    return a.name<b.name
  end)
  return out
end
function DB:DecodeClassMask(mask)
  mask=tonumber(mask or 0) or 0
  local out={}
  local labels={
    {1,"WARRIOR"},
    {2,"PALADIN"},
    {3,"HUNTER"},
    {4,"ROGUE"},
    {5,"PRIEST"},
    {6,"DEATHKNIGHT"},
    {7,"SHAMAN"},
    {8,"MAGE"},
    {9,"WARLOCK"},
    {11,"DRUID"},
  }
  for i=1,#labels do
    local classID,label=labels[i][1],labels[i][2]

    local b=pow2(classID-1)
    if bit and bit.band then
      if bit.band(mask,b)~=0 then out[#out+1]=label end
    else
      if math.floor(mask/b)%2==1 then out[#out+1]=label end
    end
  end
  return out
end

local evt=CreateFrame("Frame")
evt:RegisterEvent("PLAYER_LOGIN")
evt:RegisterEvent("SPELLS_CHANGED")
evt:SetScript("OnEvent",function()
  DB:RebuildKnownSpells()
end)