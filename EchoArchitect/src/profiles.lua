local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.Profiles=EA.Profiles or {}
local P=EA.Profiles
local function deepCopy(dst,src)
  if type(dst)~="table" then dst={} end
  if type(src)~="table" then return dst end
  for k,v in pairs(src) do
    if type(v)=="table" then
      dst[k]=deepCopy(dst[k],v)
    else
      dst[k]=v
    end
  end
  return dst
end
local function deepMerge(dst,src)
  if type(dst)~="table" then dst={} end
  if type(src)~="table" then return dst end
  for k,v in pairs(src) do
    if type(v)=="table" then
      if type(dst[k])~="table" then dst[k]={} end
      deepMerge(dst[k],v)
    elseif dst[k]==nil then
      dst[k]=v
    end
  end
  return dst
end
P.defaults={
  version=1,
  profiles={},
  activeProfile=nil,
  ui={
    window={x=nil,y=nil,scale=1.0,shown=false,tab="dashboard"},
    library={sortKey="name",sortAsc=true,showAll=false,search=""},
  },
  run={
    runId=0,
    picksCount=0,
    echoLevel=2,
    history={},
    lastResetStamp=0,
  },
}
P.profileDefaults={
  _v=2,
  name="",
  weights={},
  blacklist={},
  buckets={},
  echoBucket={},
  automation={
    showStartStopButton=true,
    hidePerkFrameWhileRunning=false,
    enablePick=true,
    enableReroll=true,
    enableBanish=true,
    speed=0.25,
    pauseIfMultipleAbove=false,
    threshold=0,
    pauseIfOnlyBlacklisted=true,
    aggressiveness=0.5,
    maxContinuousRerolls=1,
    minLevelBeforeRerolling=12,
    minKeepScore=0,
  },
  scoring={
    ownedPenalty=0,
    qualityBonus={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0},
    qualityMultiplier={[0]=1,[1]=1,[2]=1,[3]=1,[4]=1},
  },
  goals={
    thresholds={},
  },
  stats={
    gearBaseline={},
  },
}
local function ensureDefaultBucket(pr)
  if type(pr)~="table" then return end
  pr.buckets=pr.buckets or {}
  pr.echoBucket=pr.echoBucket or {}
  if pr.buckets["b_default"]==nil and not next(pr.buckets) then
    pr.buckets["b_default"]={name="The Bucket",maxStacks=0,echoKeys={}}
  end
end

EchoArchitect_CharDB=EchoArchitect_CharDB or {}
local _bootdb=EchoArchitect_CharDB
deepMerge(_bootdb,P.defaults)
_bootdb.profiles=_bootdb.profiles or {}

function P:GetCharKey()
  local n=UnitName and UnitName("player") or "Player"
  return tostring(n)
end
function P:Init()
  EchoArchitect_CharDB=EchoArchitect_CharDB or {}
  local db=EchoArchitect_CharDB
  deepMerge(db,self.defaults)
  db.profiles=db.profiles or {}
  local key=self:GetCharKey()
  local old=db.activeProfile
  if type(old)=="string" and old~=key then
    local n=key
    if string.sub(old,1,#n+1)==(n.."-") then
      if type(db.profiles[key])~="table" and type(db.profiles[old])=="table" then
        db.profiles[key]=deepCopy({},db.profiles[old])
        db.profiles[key].name=key
      end
      db.activeProfile=key
    end
  end
  if not db.activeProfile then db.activeProfile=key end
  if type(db.profiles[db.activeProfile])~="table" then
    db.profiles[db.activeProfile]={name=db.activeProfile}
  end
  deepMerge(db.profiles[db.activeProfile],self.profileDefaults)
  ensureDefaultBucket(db.profiles[db.activeProfile])
  if db.profiles[db.activeProfile].name=="" then db.profiles[db.activeProfile].name=db.activeProfile end
  return db
end
function P:GetDB()
  return EchoArchitect_CharDB
end
function P:GetActiveProfile()
  local db=self:GetDB()
  if not db then return nil end
  local name=db.activeProfile
  if not name then return nil end
  local pr=db.profiles and db.profiles[name]
  if type(pr)~="table" then return nil end
  deepMerge(pr,self.profileDefaults)
  if (tonumber(pr._v) or 1)<2 then
    pr._v=2
    local op=tonumber(pr.scoring and pr.scoring.ownedPenalty or 0) or 0
    if op>0 and op<=1 then
      pr.scoring.ownedPenalty=math.floor(op*100+0.5)
    end
    pr.scoring.qualityBonus={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0}
    pr.scoring.qualityMultiplier={[0]=1,[1]=1,[2]=1,[3]=1,[4]=1}
    if pr.automation and pr.automation.safetyLock~=nil then pr.automation.safetyLock=nil end
  end
  ensureDefaultBucket(pr)
  return pr
end
function P:EnsureProfile(name)
  if type(name)~="string" or name=="" then return nil end
  local db=self:GetDB()
  db.profiles=db.profiles or {}
  if type(db.profiles[name])~="table" then
    db.profiles[name]={name=name}
  end
  deepMerge(db.profiles[name],self.profileDefaults)
  ensureDefaultBucket(db.profiles[name])
  return db.profiles[name]
end
function P:SetActiveProfile(name)
  if type(name)~="string" or name=="" then return false end
  local db=self:GetDB()
  self:EnsureProfile(name)
  db.activeProfile=name
  return true
end
function P:DeleteProfile(name)
  local db=self:GetDB()
  if not db or not db.profiles then return false end
  if name==db.activeProfile then return false end
  db.profiles[name]=nil
  return true
end
function P:CloneProfile(srcName,newName)
  local db=self:GetDB()
  if not db or not db.profiles then return false,"db" end
  if type(srcName)~="string" or type(newName)~="string" then return false,"name" end
  if srcName=="" or newName=="" then return false,"name" end
  local src=db.profiles[srcName]
  if type(src)~="table" then return false,"src" end
  local dst={}
  deepCopy(dst,src)
  dst.name=newName
  db.profiles[newName]=dst
  deepMerge(db.profiles[newName],self.profileDefaults)
  return true,nil
end
function P:ExportProfile(name)
  local db=self:GetDB()
  if not db or not db.profiles then return "" end
  local pr=db.profiles[name]
  if type(pr)~="table" then return "" end
  return EA.Serialize:Export(pr)
end
function P:ImportProfile(name,str)
  local tbl,err=EA.Serialize:Import(str)
  if not tbl then return false,err end
  local db=self:GetDB()
  db.profiles=db.profiles or {}
  tbl.name=name
  deepMerge(tbl,self.profileDefaults)
  db.profiles[name]=tbl
  return true,nil
end
