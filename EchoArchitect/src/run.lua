local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.Run=EA.Run or {}
local R=EA.Run
local function now()
  return time and time() or 0
end
function R:GetRun()
  local db=EchoArchitect_CharDB
  if not db then return nil end
  db.run=db.run or {runId=0,picksCount=0,echoLevel=2,history={},lastResetStamp=0}
  db.run.history=db.run.history or {}
  db.run.echoLevel=tonumber(db.run.echoLevel or 2) or 2
  db.run.picksCount=tonumber(db.run.picksCount or 0) or 0
  return db.run
end
function R:ResetRun()
  local run=self:GetRun()
  if not run then return end
  local t=now()
  run.runId=(tonumber(run.runId or 0) or 0)+1
  run.history={}
  run.picksCount=0
  run.echoLevel=2
  run.lastResetStamp=t
  run._completed=false
  run._lastPickSig=nil
  run._lastPickT=nil
end

function R:MaybeReset()
  local run=self:GetRun()
  if not run then return end
  local lvl=UnitLevel and UnitLevel("player") or 0
  local picks=tonumber(run.picksCount or 0) or 0
  if lvl==1 and picks==0 then
    local t=now()
    local last=tonumber(run.lastResetStamp or 0) or 0
    if t-last>2 then
      self:ResetRun()
    end
  end
end

function R:TrackLevelOne()
  local db=EchoArchitect_CharDB
  if not db then return end
  db.runState=db.runState or {lastLevel=0,completedAt80=false,resetLatch=false}
  local st=db.runState
  local lvl=UnitLevel and UnitLevel("player") or 0
  if lvl==80 then st.completedAt80=true end
  if lvl==1 then
    if not st.resetLatch then
      st.resetLatch=true
      if st.completedAt80 then
        st.completedAt80=false
        if EA and EA.Logbook and EA.Logbook.RecordRunCompleted then
          EA.Logbook:RecordRunCompleted()
        end
      end
      self:ResetRun()
    end
  else
    st.resetLatch=false
  end
  st.lastLevel=lvl
end
function R:EchoLevel()
  local run=self:GetRun()
  if not run then return 2 end
  return tonumber(run.echoLevel or 2) or 2
end
function R:AdvancePick()
  local run=self:GetRun()
  if not run then return end
  run.picksCount=(tonumber(run.picksCount) or 0)+1
  run.echoLevel=(tonumber(run.echoLevel) or 2)+1
end
function R:Record(entry)
  local run=self:GetRun()
  if not run or type(entry)~="table" then return end
  entry.t=now()
  if entry.action=="Pick" then
    local best=tonumber(entry.best or 0) or 0
    local el=tonumber(entry.echoLevel or 0) or 0
    local o=entry.offered
    local a=0
    local b=0
    local c=0
    if type(o)=="table" then
      if o[1] then a=tonumber(o[1].spellId or 0) or 0 end
      if o[2] then b=tonumber(o[2].spellId or 0) or 0 end
      if o[3] then c=tonumber(o[3].spellId or 0) or 0 end
    end
    local sig=el..":"..best..":"..a..":"..b..":"..c
    local lastSig=run._lastPickSig
    local lastT=tonumber(run._lastPickT or 0) or 0
    if lastSig==sig and (entry.t-lastT)<=2 then return end
    run._lastPickSig=sig
    run._lastPickT=entry.t
  end
  run.history=run.history or {}
  run.history[#run.history+1]=entry
end
function R:MarkCompletedIfNeeded()
  local run=self:GetRun()
  if not run then return false end
  if run._completed then return false end
  local picks=tonumber(run.picksCount or 0) or 0
  if picks>=79 then
    run._completed=true
    return true
  end
  return false
end

function R:GetSessionState()
  local db=EchoArchitect_CharDB
  if not db then return nil end
  db.session=db.session or {active=false,startTime=0,startLevel=2,lastLevel=0,lastXP=0,totalXP=0,firstRare=0,firstEpic=0,firstLegendary=0,completed=false,completedDuration=0,completedXP=0,shadowsteps=0}
  local s=db.session
  if s.active==nil then s.active=false end
  s.startTime=tonumber(s.startTime or 0) or 0
  s.startLevel=tonumber(s.startLevel or 2) or 2
  s.lastLevel=tonumber(s.lastLevel or 0) or 0
  s.lastXP=tonumber(s.lastXP or 0) or 0
  s.totalXP=tonumber(s.totalXP or 0) or 0
  s.firstRare=tonumber(s.firstRare or 0) or 0
  s.firstEpic=tonumber(s.firstEpic or 0) or 0
  s.firstLegendary=tonumber(s.firstLegendary or 0) or 0
  s.shadowsteps=tonumber(s.shadowsteps or 0) or 0
  if s.completed==nil then s.completed=false end
  s.completedDuration=tonumber(s.completedDuration or 0) or 0
  s.completedXP=tonumber(s.completedXP or 0) or 0
  return s
end

function R:ResetSession()
  local s=self:GetSessionState()
  if not s then return end
  s.active=false
  s.startTime=0
  s.startLevel=2
  s.lastLevel=0
  s.lastXP=0
  s.lastXPMax=0
  s.totalXP=0
  s.activeSeconds=0
  s.lastXpStamp=0
  s.firstRare=0
  s.firstEpic=0
  s.firstLegendary=0
  s.completed=false
  s.completedDuration=0
  s.completedXP=0
  s.completedActiveSeconds=0
  s.shadowsteps=0
end


function R:SyncSessionToCurrentLevel()
  local lvl=(UnitLevel and UnitLevel("player")) or 0
  if lvl==1 then
    self:ResetSession()
    return
  end
  if lvl==2 then
    local s=self:GetSessionState()
    if s and not s.active and not s.completed then
      self:StartSessionIfNeeded(2)
    end
    return
  end
  if lvl>2 and lvl<80 then
    local s=self:GetSessionState()
    if s and not s.active and not s.completed then
      s.active=true
      s.startTime=now()
      s.lastLevel=lvl
      s.lastXP=(UnitXP and UnitXP("player")) or 0
      s.lastXPMax=(UnitXPMax and UnitXPMax("player")) or 0
      s.totalXP=0
      s.activeSeconds=0
      s.lastTick=now()
    end
  end
  if lvl>=80 then
    self:EndSessionIfNeeded(80)
  end
end
function R:StartSessionIfNeeded(newLevel)
  if newLevel~=2 then return end
  local s=self:GetSessionState()
  if not s then return end
  s.active=true
  s.startTime=now()
  s.lastLevel=2
  s.lastXP=(UnitXP and UnitXP("player")) or 0
  s.lastXPMax=(UnitXPMax and UnitXPMax("player")) or 0
  s.totalXP=0
  s.activeSeconds=0
  s.lastXpStamp=0
  s.firstRare=0
  s.firstEpic=0
  s.firstLegendary=0
  s.completed=false
  s.completedDuration=0
  s.completedXP=0
  s.completedActiveSeconds=0
  s.shadowsteps=0
end


function R:OnShadowstepCast()
  local s=self:GetSessionState()
  if not s or not s.active then return end
  s.shadowsteps=(tonumber(s.shadowsteps or 0) or 0)+1
end

function R:ShadowstepsPerMinute()
  local s=self:GetSessionState()
  if not s then return 0 end
  local n=tonumber(s.shadowsteps or 0) or 0
  local dur=0
  if s.active then
    dur=now()-(tonumber(s.startTime or 0) or 0)
  elseif s.completed then
    dur=tonumber(s.completedDuration or 0) or 0
  end
  if dur<=0 then return 0 end
  return n/(dur/60)
end
function R:EndSessionIfNeeded(newLevel)
  if newLevel~=80 then return end
  local s=self:GetSessionState()
  if not s or not s.active then return end
  self:OnXPUpdate()
  s.active=false
  local dur=now()-(tonumber(s.startTime or 0) or 0)
  s.completed=true
  s.completedDuration=dur
  s.completedXP=tonumber(s.totalXP or 0) or 0
  s.completedActiveSeconds=tonumber(s.activeSeconds or 0) or 0
  if EA and EA.Logbook and EA.Logbook.RecordSessionComplete then
    EA.Logbook:RecordSessionComplete(dur,tonumber(s.totalXP or 0) or 0,tonumber(s.firstRare or 0) or 0,tonumber(s.firstEpic or 0) or 0,tonumber(s.firstLegendary or 0) or 0,tonumber(s.activeSeconds or 0) or 0)
  end
end

function R:OnLevelUp(newLevel)
  newLevel=tonumber(newLevel or 0) or 0
  if newLevel==1 then
    self:ResetSession()
  end
  local db=EchoArchitect_CharDB
  local st=db and db.runState
  if st and newLevel==80 then st.completedAt80=true end
  self:StartSessionIfNeeded(newLevel)
  self:EndSessionIfNeeded(newLevel)
  local s=self:GetSessionState()
  if not s then return end
  s.lastLevel=newLevel
  s.lastXP=(UnitXP and UnitXP("player")) or 0
  s.lastXPMax=(UnitXPMax and UnitXPMax("player")) or 0
end

function R:OnXPUpdate()
  local s=self:GetSessionState()
  if not s or not s.active then return end
  local t=now()
  local lvl=(UnitLevel and UnitLevel("player")) or 0
  local xp=(UnitXP and UnitXP("player")) or 0
  local xpMax=(UnitXPMax and UnitXPMax("player")) or 0
  local lastLevel=tonumber(s.lastLevel or 0) or 0
  local lastXP=tonumber(s.lastXP or 0) or 0
  local lastXPMax=tonumber(s.lastXPMax or 0) or 0
  local gained=0
  if lvl==lastLevel then
    gained=xp-lastXP
  else
    if lvl>lastLevel and lastLevel>0 then
      gained=(lastXPMax-lastXP)+xp
    end
  end
  if gained>0 then
    s.totalXP=(tonumber(s.totalXP or 0) or 0)+gained
    local lastStamp=tonumber(s.lastXpStamp or 0) or 0
    local dt=0
    if lastStamp>0 then
      dt=t-lastStamp
    else
      dt=t-(tonumber(s.startTime or t) or t)
    end
    if dt<0 then dt=0 end
    if dt>120 then dt=120 end
    s.activeSeconds=(tonumber(s.activeSeconds or 0) or 0)+dt
    s.lastXpStamp=t
  end
  s.lastLevel=lvl
  s.lastXP=xp
  s.lastXPMax=xpMax
end

function R:NoteFirstQuality(q)
  local s=self:GetSessionState()
  if not s or not s.active then return end
  local run=self:GetRun()
  local el=0
  if run then
    el=tonumber(run.echoLevel or 0) or 0
    if el<=0 then el=(tonumber(run.picksCount or 0) or 0)+2 end
  end
  if el<=0 then return end
  if q==2 and (tonumber(s.firstRare or 0) or 0)==0 then s.firstRare=el local Log=EA and EA.Logbook if Log and Log.RecordFirstQuality then Log:RecordFirstQuality(2,el) end end
  if q==3 and (tonumber(s.firstEpic or 0) or 0)==0 then s.firstEpic=el local Log=EA and EA.Logbook if Log and Log.RecordFirstQuality then Log:RecordFirstQuality(3,el) end end
  if q==4 and (tonumber(s.firstLegendary or 0) or 0)==0 then s.firstLegendary=el local Log=EA and EA.Logbook if Log and Log.RecordFirstQuality then Log:RecordFirstQuality(4,el) end end
end