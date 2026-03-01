local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.Engine=EA.Engine or {}
local E=EA.Engine
local DB=EA.DB
local Run=EA.Run
local Log=EA.Logbook
E.state={enabled=false,lastHash=nil,lastAct=0,rerollsThisOffer=0,contRerolls=0}
E._hooks=false
local decide
local function now()
  return GetTime and GetTime() or 0
end
local function chat(msg)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage(msg) end
end
local function getRunData()
  if ProjectEbonhold and ProjectEbonhold.PlayerRunService and ProjectEbonhold.PlayerRunService.GetCurrentData then
    local ok,res=pcall(ProjectEbonhold.PlayerRunService.GetCurrentData)
    if ok and type(res)=="table" then return res end
  end
  if type(_G.EbonholdPlayerRunData)=="table" then return _G.EbonholdPlayerRunData end
  return {}
end
local function rerollsRemaining(pr)
  local rd=getRunData()
  local remField=tonumber(rd.remainingRerolls or rd.rerollsRemaining or rd.rerollsLeft or rd.rerollCharges or 0) or 0
  if remField>0 then return remField,remField,0 end
  local used=tonumber(rd.usedRerolls or rd.rerollsUsed or 0) or 0
  local total=tonumber(rd.totalRerolls or rd.rerollsTotal or 0) or 0
  if total>0 then return math.max(0,total-used),total,used end
  local maxRow=pr and pr.automation and tonumber(pr.automation.maxRerollsPerOffer) or nil
  if not maxRow then maxRow=10 end
  local rem=math.max(0,(tonumber(maxRow) or 10)-(tonumber(E.state.rerollsThisOffer) or 0))
  return rem,tonumber(maxRow) or 10,tonumber(E.state.rerollsThisOffer) or 0
end
local function banishesRemaining()
  if not (ProjectEbonhold and ProjectEbonhold.Constants and ProjectEbonhold.Constants.ENABLE_BANISH_SYSTEM) then return 0 end
  local rd=getRunData()
  return tonumber(rd.remainingBanishes or 0) or 0
end
local function countOwnedStacks(spellId)
  local grantedN,grantedMax=0,nil
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.GetGrantedPerks then
    local ok,granted=pcall(ProjectEbonhold.PerkService.GetGrantedPerks)
    if ok and type(granted)=="table" then
      local name=GetSpellInfo(spellId)
      if name then
        local list=granted[name]
        if type(list)=="table" then
          grantedN=#list
          if grantedN>0 then grantedMax=tonumber(list[1].maxStack) end
        end
      end
    end
  end
  local lockedN,lockedMax=0,nil
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.GetLockedPerks then
    local ok,locked=pcall(ProjectEbonhold.PerkService.GetLockedPerks)
    if ok and type(locked)=="table" then
      for i=1,#locked do
        local ent=locked[i]
        if ent and tonumber(ent.spellId or 0)==tonumber(spellId or 0) then
          lockedN=lockedN+(tonumber(ent.stack or 0) or 0)
          local ms=tonumber(ent.maxStack)
          if ms then lockedMax=lockedMax and math.max(lockedMax,ms) or ms end
        end
      end
    end
  end
  local maxStack=grantedMax
  if lockedMax then maxStack=maxStack and math.max(maxStack,lockedMax) or lockedMax end
  return (grantedN+lockedN),maxStack
end
local function normalizeChoice(raw)
  if not raw then return nil end
  local sid=tonumber(raw.spellId or raw.spellID or raw.id or 0) or 0
  if sid==0 then return nil end
  local meta=DB:GetPerkMeta(sid) or {}
  local q=tonumber(raw.quality or meta.quality or 0) or 0
  local key=DB:MakeKey(sid,q)
  local name,_,icon=GetSpellInfo(sid)
  return {spellId=sid,quality=q,key=key,name=name or ("Spell "..tostring(sid)),icon=icon,index=tonumber(raw.index) or nil}
end
local function getCurrentOfferEx()
  local cc=nil
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.GetCurrentChoice then
    cc=ProjectEbonhold.PerkService.GetCurrentChoice()
  elseif ProjectEbonhold and ProjectEbonhold.Perks and type(ProjectEbonhold.Perks.currentChoice)=="table" then
    cc=ProjectEbonhold.Perks.currentChoice
  end
  if type(cc)~="table" or #cc==0 then return nil,nil end
  local out={}
  for i=1,#cc do
    local c=normalizeChoice(cc[i])
    if c then c.index=i out[#out+1]=c end
  end
  if #out==0 then return nil,cc end
  return out,cc
end

function E:GetUISnapshot()
  local pr=EA.Profiles and EA.Profiles.GetActiveProfile and EA.Profiles:GetActiveProfile() or nil
  local offer,offerRef=getCurrentOfferEx()
  local res=nil
  if pr and offer and type(offer)=="table" and #offer>0 and decide then
    res=decide(pr,offer)
  end
  local remR,totalR,usedR=0,0,0
  if pr then
    remR,totalR,usedR=rerollsRemaining(pr)
  end
  local banR=banishesRemaining()
  local lvl=(UnitLevel and UnitLevel("player")) or 0
  local run=EA.Run and EA.Run.GetRun and EA.Run:GetRun() or nil
  local picks=run and tonumber(run.picksCount or 0) or 0
  local s=nil
  if EA.Run and EA.Run.GetSessionState then
  s=EA.Run and EA.Run.GetSessionState and EA.Run:GetSessionState()
  end
  local activeSession=(s and s.active==true) or false
  local lastOfferT=tonumber(self.state.lastOfferT or 0) or 0
  local t=now()
  local sinceOffer=nil
  if activeSession and lastOfferT>0 then
    sinceOffer=math.max(0,t-lastOfferT)
  end
  return {
    enabled=self.state.enabled==true,
    pausedReason=self.state.pausedReason,
    offer=offer,
    offerRef=offerRef,
    decision=res,
    rerollsRemaining=remR,
    rerollsTotal=totalR,
    rerollsUsed=usedR,
    banishesRemaining=banR,
    playerLevel=lvl,
    picksCount=picks,
    echoLevel=(run and tonumber(run.echoLevel or 2)) or 2,
    sinceOffer=sinceOffer,
    sessionActive=activeSession,
  }
end
local function getCurrentOffer()
  local offer=select(1,getCurrentOfferEx())
  return offer
end
local function hashOffer(choices)
  local parts={}
  for i=1,#choices do
    local c=choices[i]
    parts[#parts+1]=tostring(c.spellId or 0)..":"..tostring(c.quality or 0)
  end
  table.sort(parts)
  return table.concat(parts,"|")
end
local function spellIdFromKey(key)
  if not key then return 0 end
  local a=string.match(tostring(key),"^(%d+):")
  return tonumber(a or 0) or 0
end
local function bucketOverCap(pr,key)
  if not pr or not pr.echoBucket or not pr.buckets then return false,0,0 end
  local bid=pr.echoBucket[key]
  if not bid then return false,0,0 end
  local b=pr.buckets[bid]
  if type(b)~="table" then return false,0,0 end
  if b.enabled==false then return false,0,tonumber(b.maxStacks or 0) or 0 end
  local cap=tonumber(b.maxStacks or 0) or 0
  if cap<=0 then return false,0,cap end
  local total=0
  if type(b.echoKeys)=="table" then
    for ek in pairs(b.echoKeys) do
      local sid=spellIdFromKey(ek)
      if sid>0 then
        local n=countOwnedStacks(sid)
        total=total+(tonumber(n) or 0)
      end
    end
  end
  if total>=cap then return true,total,cap end
  return false,total,cap
end
local function isBlacklisted(pr,key)
  if pr and pr.blacklist and pr.blacklist[key]==true then return true,"blacklisted" end
  local over= bucketOverCap(pr,key)
  if over then return true,"bucketcap" end
  return false,nil
end
local function weightFor(pr,key)
  if not pr or not pr.weights then return 0 end
  local w=pr.weights[key]
  if w==nil then return 0 end
  return tonumber(w) or 0
end
local function scoreChoice(pr,c)
  local owned,ms=countOwnedStacks(c.spellId)
  local bl,why=isBlacklisted(pr,c.key)
  if bl then
    return -1e9,why or "blacklisted",owned,ms
  end
  local base=weightFor(pr,c.key)
  local q=c.quality or 0
  local bonus=0
  local mult=1
  if pr and pr.scoring and pr.scoring.qualityBonus then bonus=tonumber(pr.scoring.qualityBonus[q] or 0) or 0 end
  if pr and pr.scoring and pr.scoring.qualityMultiplier then mult=tonumber(pr.scoring.qualityMultiplier[q] or 1) or 1 end
  local ownedPenalty=tonumber(pr and pr.scoring and pr.scoring.ownedPenalty or 0) or 0
  if ownedPenalty>1 then ownedPenalty=ownedPenalty/100 end
  local ownedFactor=1
  local ownedReason=""
  if owned and owned>0 and ownedPenalty>0 then
    ownedFactor=math.max(0,1-ownedPenalty)
    ownedReason="owned"..tostring(owned)
  end
  local s=(base+bonus)*mult*ownedFactor
  local why="w"..tostring(base)
  if bonus~=0 then why=why.."+q"..tostring(bonus) end
  if mult~=1 then why=why.."*m"..tostring(mult) end
  if ownedReason~="" then why=why.."*"..ownedReason end
  return s,why,owned,ms
end
local function onlyBlacklisted(pr,choices)
  for i=1,#choices do
    local c=choices[i]
    local bl=isBlacklisted(pr,c.key)
    if not bl then
      local w=weightFor(pr,c.key)
      if w>=0 then return false end
    end
  end
  return true
end
local function bestByScore(scores)
  local bestI,bestS=1,-1e18
  for i=1,#scores do
    if scores[i].score>bestS then bestS=scores[i].score bestI=i end
  end
  return bestI,bestS
end
local function countAbove(scores,thr)
  local n=0
  for i=1,#scores do if scores[i].score>=thr then n=n+1 end end
  return n
end
local function canAct(pr)
  if not pr or not pr.automation then return false end
  return true
end
local function actDelay(pr)
  local d=tonumber(pr.automation and pr.automation.speed or 0.18) or 0.18
  if d<0.05 then d=0.05 end
  if d>1.5 then d=1.5 end
  return d
end
local function selectPerk(spellId)
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.SelectPerk then
    return ProjectEbonhold.PerkService.SelectPerk(spellId)
  end
  if ProjectEbonhold and ProjectEbonhold.Perks and ProjectEbonhold.Perks.SelectPerk then
    return ProjectEbonhold.Perks.SelectPerk(spellId)
  end
  return false
end
local function requestReroll()
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.RequestReroll then
    ProjectEbonhold.PerkService.RequestReroll() return true
  end
  if ProjectEbonhold and ProjectEbonhold.Perks and ProjectEbonhold.Perks.RequestReroll then
    ProjectEbonhold.Perks.RequestReroll() return true
  end
  return false
end
local function banishIndex(idx0)
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.BanishPerk then
    return ProjectEbonhold.PerkService.BanishPerk(idx0)
  end
  if ProjectEbonhold and ProjectEbonhold.Perks and ProjectEbonhold.Perks.BanishPerk then
    return ProjectEbonhold.Perks.BanishPerk(idx0)
  end
  return false
end
local function buildScorePack(pr,choices)
  local scores={}
  for i=1,#choices do
    local c=choices[i]
    local s,why,owned,ms=scoreChoice(pr,c)
    scores[i]={choice=c,score=s,why=why,owned=owned,maxStack=ms}
  end
  return scores
end
decide=function(pr,choices)
  local scores=buildScorePack(pr,choices)
  local a=pr and pr.automation or nil
  local thr=tonumber(a and a.threshold or 0) or 0
  if a and a.pauseIfMultipleAbove and thr>0 then
    local n=0
    for i=1,#scores do
      local s=scores[i]
      local key=s and s.choice and s.choice.key or nil
      if key then
        if s.score>-1e8 then
          local w=weightFor(pr,key)
          if w>=thr then n=n+1 end
        end
      end
    end
    if n>=2 then
      return {action="pause",reason="multipleAboveThreshold",scores=scores,bestI=1}
    end
  end
  local minKeep=tonumber(a and a.minKeepScore or 0) or 0
  local bestAboveI=nil
  local bestAboveS=-1e18
  for i=1,#scores do
    local sc=scores[i].score
    if sc>=minKeep and sc>bestAboveS then
      bestAboveS=sc
      bestAboveI=i
    end
  end
  if bestAboveI then
    return {action="pick",reason="aboveMinKeep",scores=scores,bestI=bestAboveI}
  end
  local anyBL=false
  local firstBLI=nil
  local allBL=true
  for i=1,#scores do
    local key=scores[i] and scores[i].choice and scores[i].choice.key or nil
    local bl=isBlacklisted(pr,key)
    if bl then
      anyBL=true
      if not firstBLI then firstBLI=i end
    else
      local w=weightFor(pr,key)
      if w>=0 then allBL=false end
    end
  end
  local banRem=banishesRemaining()
  local canBanish=(a and a.enableBanish) and banRem>0 and anyBL
  local run=EA.Run and EA.Run.GetRun and EA.Run:GetRun() or nil
  local echoPick=((run and tonumber(run.picksCount or 0) or 0) or 0)+2
  local minLvl=tonumber(a and a.minLevelBeforeRerolling or 1) or 1
  local maxCont=tonumber(a and a.maxContinuousRerolls or 0) or 0
  local cont=tonumber(E.state.contRerolls) or 0
  local rem=rerollsRemaining(pr)
  local canByMin=echoPick>=minLvl
  local canByCont=(maxCont<=0) or (cont<maxCont)
  local canReroll=(a and a.enableReroll) and rem>0 and canByMin and canByCont
  if a and a.pauseIfOnlyBlacklisted and allBL and (not canBanish) and (not canReroll) then
    return {action="pause",reason="onlyBlacklisted",scores=scores,bestI=1}
  end
  if canBanish then
    return {action="banish",reason="blacklist",scores=scores,bestI=1,banishI=firstBLI}
  end
  if canReroll then
    return {action="reroll",reason="noAboveMinKeep",scores=scores,bestI=1}
  end
  local bestS=-1e18
  for i=1,#scores do
    local sc=scores[i].score
    if sc>bestS then bestS=sc end
  end
  local ties={}
  for i=1,#scores do
    if scores[i].score==bestS then ties[#ties+1]=i end
  end
  local pickI=ties[1] or 1
  local reason="bestBelowMinKeep"
  if #ties>1 then
    pickI=ties[math.random(1,#ties)]
    reason="randomTie"
  end
  return {action="pick",reason=reason,scores=scores,bestI=pickI}
end

local function scoresToOffer(scores,pr)
  local out={}
  for i=1,#scores do
    local s=scores[i]
    local c=s.choice or {}
    local key=c.key
    local w=0
    if pr and pr.weights and key then
      local v=pr.weights[key]
      if v~=nil then w=tonumber(v) or 0 end
    end
    local bl=false
    local blWhy=nil
    local bid=nil
    local bname=nil
    local btotal=nil
    local bcap=nil
    if pr and key then
      if pr.blacklist and pr.blacklist[key]==true then
        bl=true
        blWhy="blacklisted"
      end
      if not bl then
        local over,total,cap=bucketOverCap(pr,key)
        if over then
          bl=true
          blWhy="bucketcap"
          btotal=total
          bcap=cap
        else
          btotal=total
          bcap=cap
        end
      end
      if pr.echoBucket and pr.buckets then
        bid=pr.echoBucket[key]
        if bid and pr.buckets[bid] and pr.buckets[bid].name then bname=pr.buckets[bid].name end
      end
    end
    out[#out+1]={
      spellId=c.spellId,quality=c.quality,key=key,name=c.name,icon=c.icon,index=c.index,
      score=s.score,why=s.why,
      weight=w,
      owned=s.owned,maxStack=s.maxStack,
      blacklisted=bl,blacklistReason=blWhy,
      bucketId=bid,bucketName=bname,bucketTotal=btotal,bucketCap=bcap
    }
  end
  return out
end

local function explainDecision(pr,choices,res)
  local d={}
  d.playerLevel=UnitLevel and UnitLevel("player") or 0
  local run=EA.Run and EA.Run.GetRun and EA.Run:GetRun() or nil
  d.echoPick=((run and tonumber(run.picksCount or 0) or 0) or 0)+2
  d.offerHash=choices and hashOffer(choices) or ""
  d.action=res and res.action or ""
  d.actionReason=res and res.reason or ""
  d.contRerolls=tonumber(E.state.contRerolls) or 0
  d.rerollsThisOffer=tonumber(E.state.rerollsThisOffer) or 0
  d.enableReroll=pr and pr.automation and pr.automation.enableReroll or false
  d.enableBanish=pr and pr.automation and pr.automation.enableBanish or false
  d.threshold=tonumber(pr and pr.automation and pr.automation.threshold or 0) or 0
  d.pauseIfMultipleAbove=pr and pr.automation and pr.automation.pauseIfMultipleAbove or false
  d.pauseIfOnlyBlacklisted=pr and pr.automation and pr.automation.pauseIfOnlyBlacklisted or false
  d.minKeepScore=tonumber(pr and pr.automation and pr.automation.minKeepScore or 0) or 0
  d.aggressiveness=tonumber(pr and pr.automation and pr.automation.aggressiveness or 0) or 0
  d.effMinKeep=d.minKeepScore+d.aggressiveness
  d.minLevelBeforeRerolling=tonumber(pr and pr.automation and pr.automation.minLevelBeforeRerolling or 1) or 1
  d.maxContinuousRerolls=tonumber(pr and pr.automation and pr.automation.maxContinuousRerolls or 0) or 0
  d.maxRerollsPerOffer=tonumber(pr and pr.automation and pr.automation.maxRerollsPerOffer or 10) or 10
  local remR,totalR,usedR=rerollsRemaining(pr)
  d.rerollsRemaining=remR
  d.rerollsTotal=totalR
  d.rerollsUsed=usedR
  d.banishesRemaining=banishesRemaining()
  local scores=res and res.scores or nil
  if type(scores)=="table" then
    local bestI,bestS=bestByScore(scores)
    d.bestIndex=bestI
    d.bestScore=bestS
    local above=0
    if d.threshold and d.threshold>0 then
      for i=1,#scores do
        local s=scores[i]
        local key=s and s.choice and s.choice.key or nil
        if key then
          if s.score>-1e8 then
            local w=weightFor(pr,key)
            if w>=d.threshold then above=above+1 end
          end
        end
      end
    end
    d.aboveThreshold=above
    local blN=0
    local blIdx={}
    for i=1,#scores do
      local s=scores[i]
      local key=s and s.choice and s.choice.key or nil
      local bl,why=isBlacklisted(pr,key)
      if bl then
        blN=blN+1
        blIdx[#blIdx+1]={i=i,why=why or ""}
      end
    end
    d.blacklistedCount=blN
    d.blacklistedIndices=blIdx
  end
  d.whyNot={}
  d.whyNot.reroll={}
  d.whyNot.banish={}
  if not d.enableReroll then
    d.whyNot.reroll[#d.whyNot.reroll+1]="rerollDisabled"
  else
    if (tonumber(d.echoPick) or 0)~=(tonumber(d.minLevelBeforeRerolling) or 0) then d.whyNot.reroll[#d.whyNot.reroll+1]="echoPickNotAtMin" end
    if d.rerollsRemaining<=0 then d.whyNot.reroll[#d.whyNot.reroll+1]="noRerollsRemaining" end
    if d.maxContinuousRerolls>0 and d.contRerolls>=d.maxContinuousRerolls then d.whyNot.reroll[#d.whyNot.reroll+1]="maxContinuousRerollsReached" end
  end
  if not d.enableBanish then
    d.whyNot.banish[#d.whyNot.banish+1]="banishDisabled"
  else
    if d.banishesRemaining<=0 then d.whyNot.banish[#d.whyNot.banish+1]="noBanishesRemaining" end
    if (tonumber(d.blacklistedCount) or 0)==0 then d.whyNot.banish[#d.whyNot.banish+1]="noBlacklistedShown" end
  end
  return d
end

local function recordHistory(action,res,choices,pr)
  local run=EA.Run and EA.Run.GetRun and EA.Run:GetRun() or nil
  local el=0
  if run then el=(tonumber(run.picksCount or 0) or 0)+2 end
  local remR,totalR,usedR=rerollsRemaining(pr)
  local banR=banishesRemaining()
  local snap=EA.Stats:Compute()
  if EA.Run and EA.Run.Record then EA.Run:Record({echoLevel=el,action=action,reason=res.reason,source="auto",decision=explainDecision(pr,choices,res),offered=scoresToOffer(res.scores,pr),best=res.bestI,banishI=res.banishI,rerollsLeft=remR,banishesLeft=banR,stats=snap.effective}) end
end

function E:_RecordManual(action,spellId,idx0)
  local pr=EA.Profiles and EA.Profiles:GetActiveProfile() or nil
  local offer=getCurrentOffer() or {}
  local scores=buildScorePack(pr,offer)
  local best=nil
  if spellId then
    for i=1,#offer do
      if tonumber(offer[i].spellId or 0)==tonumber(spellId or 0) then best=i break end
    end
  end
  if idx0~=nil then best=(tonumber(idx0) or 0)+1 end
  local remR=0
  local banR=0
  if pr then
    remR=select(1,rerollsRemaining(pr))
    banR=banishesRemaining()
  end
  local snap=EA.Stats and EA.Stats.Compute and EA.Stats:Compute() or {effective={}}
  local bi=nil
  if action=="Banish" and idx0~=nil then bi=(tonumber(idx0) or 0)+1 end
  local run=EA.Run and EA.Run.GetRun and EA.Run:GetRun() or nil
  local el=0
  if run then el=(tonumber(run.picksCount or 0) or 0)+2 end
  if EA.Run and EA.Run.Record then EA.Run:Record({echoLevel=el,action=action,reason="manual",source="manual",decision=explainDecision(pr,offer,{action=string.lower(tostring(action or "")),reason="manual",scores=scores,bestI=best,banishI=bi}),offered=scoresToOffer(scores,pr),best=best,banishI=bi,rerollsLeft=remR,banishesLeft=banR,stats=snap.effective}) end
end

function E:_EnsureHooks()
  if self._hooks then return end
  self._hooks=true
  local function wrap(obj,fn,kind)
    if not obj or type(obj[fn])~="function" then return end
    local key=tostring(obj)..":"..fn
    self._orig=self._orig or {}
    if self._orig[key] then return end
    local orig=obj[fn]
    self._orig[key]=orig
    obj[fn]=function(...)
      local isAuto=(self.state._autoAction==kind)
      local r=orig(...)
      if isAuto then
        self.state._autoAction=nil
      else
        if kind=="pick" then
          local sid=select(1,...)
          if r then
            local pr=EA.Profiles and EA.Profiles:GetActiveProfile() or nil
            local offer=getCurrentOffer()
            if offer then
              local c=nil
              for i=1,#offer do if tonumber(offer[i].spellId or 0)==tonumber(sid or 0) then c=offer[i] break end end
              if c then
                Log:RecordPick(c)
                Run:AdvancePick()
                if Run:MarkCompletedIfNeeded() then
                  Log:RecordRunCompleted()
                  local lvl=(UnitLevel and UnitLevel("player")) or 0
                  if lvl>=80 then
                    self.state.pausedReason="sessionComplete"
                    self:SetEnabled(false)
                  end
                end
              end
            end
            if self.state and self.state.pausedReason and self.state.pausedReason~="sessionComplete" then
              self.state.pausedReason=nil
              self.state.lastAct=now()
              self:SetEnabled(true)
            end
            self.state._expectNewOffer="pick"
            self:_RecordManual("Pick",sid,nil)
          end
        elseif kind=="reroll" then
          if r then
            local pr=EA.Profiles and EA.Profiles:GetActiveProfile() or nil
            local offer=getCurrentOffer()
            if offer then Log:RecordRerollPast(offer) end
            self.state._expectNewOffer="reroll"
            self:_RecordManual("Reroll",nil,nil)
          end
        elseif kind=="banish" then
          local idx0=select(1,...)
          if r then
            local offer=getCurrentOffer()
            local idx=(tonumber(idx0) or 0)+1
            if offer and offer[idx] then Log:RecordBanish(offer[idx]) end
            self.state._expectNewOffer="banish"
            self:_RecordManual("Banish",nil,idx0)
          end
        end
      end
      return r
    end
  end
  if ProjectEbonhold and ProjectEbonhold.PerkService then
    wrap(ProjectEbonhold.PerkService,"SelectPerk","pick")
    wrap(ProjectEbonhold.PerkService,"RequestReroll","reroll")
    wrap(ProjectEbonhold.PerkService,"RerollPerk","reroll")
    wrap(ProjectEbonhold.PerkService,"Reroll","reroll")
    wrap(ProjectEbonhold.PerkService,"BanishPerk","banish")
  end
  if ProjectEbonhold and ProjectEbonhold.Perks then
    wrap(ProjectEbonhold.Perks,"SelectPerk","pick")
    wrap(ProjectEbonhold.Perks,"RequestReroll","reroll")
    wrap(ProjectEbonhold.Perks,"RerollPerk","reroll")
    wrap(ProjectEbonhold.Perks,"Reroll","reroll")
    wrap(ProjectEbonhold.Perks,"BanishPerk","banish")
  end
end
local function applyDecision(res,choices,pr)
  if res.action=="pause" then
    recordHistory("Pause",res,choices,pr)
    E.state.contRerolls=0
    E.state.pausedReason=res.reason
    E:SetEnabled(false)
    return
  end
  E.state.pausedReason=nil
  if res.action=="reroll" then
    recordHistory("Reroll",res,choices,pr)
    Log:RecordRerollPast(scoresToOffer(res.scores,pr))
    E.state.rerollsThisOffer=(tonumber(E.state.rerollsThisOffer) or 0)+1
    E.state.contRerolls=(tonumber(E.state.contRerolls) or 0)+1
    E.state._autoAction="reroll"
    E.state._expectNewOffer="reroll"
    requestReroll()
    return
  end
  if res.action=="banish" then
    recordHistory("Banish",res,choices,pr)
    local idx=res.banishI
    if idx and choices[idx] then
      Log:RecordBanish(choices[idx])
      E.state._autoAction="banish"
      E.state._expectNewOffer="banish"
      banishIndex((tonumber(choices[idx].index) or idx)-1)
    end
    return
  end
  if res.action=="pick" then
    recordHistory("Pick",res,choices,pr)
    E.state.contRerolls=0
    local c=choices[res.bestI]
    if c then
      Log:RecordPick(c)
      E.state._autoAction="pick"
      E.state._expectNewOffer="pick"
      local ok=selectPerk(c.spellId)
      if ok then
        Run:AdvancePick()
        if Run:MarkCompletedIfNeeded() then
          Log:RecordRunCompleted()
          local lvl=(UnitLevel and UnitLevel("player")) or 0
          if lvl>=80 then
            E.state.pausedReason="sessionComplete"
            E:SetEnabled(false)
          end
        end
      end
    end
    return
  end
end
function E:_HidePerkFrameNow()
  local f=_G.ProjectEbonholdPerkFrame
  if f and f.Hide then
    f:Hide()
    if f.SetAlpha then f:SetAlpha(0) end
    if f.EnableMouse then f:EnableMouse(false) end
  end
end
function E:_ShowPerkFrameIfNeeded()
  local ui=ProjectEbonhold and ProjectEbonhold.PerkUI
  if not ui then return end
  local show=self._perkOrig and self._perkOrig.Show or ui.Show
  if type(show)~="function" then return end
  local cc=nil
  if ProjectEbonhold and ProjectEbonhold.PerkService and ProjectEbonhold.PerkService.GetCurrentChoice then
    cc=ProjectEbonhold.PerkService.GetCurrentChoice()
  elseif ProjectEbonhold and ProjectEbonhold.Perks and type(ProjectEbonhold.Perks.currentChoice)=="table" then
    cc=ProjectEbonhold.Perks.currentChoice
  end
  if type(cc)~="table" or #cc==0 then return end
  local f=_G.ProjectEbonholdPerkFrame
  if f and f.IsShown and f:IsShown() then return end
  pcall(function() show(cc) end)
end
function E:_HookPerkUI()
  if self._perkHooked then return end
  local ui=ProjectEbonhold and ProjectEbonhold.PerkUI
  if not ui then return end
  self._perkOrig=self._perkOrig or {}
  if type(ui.Show)=="function" and not self._perkOrig.Show then self._perkOrig.Show=ui.Show end
  if type(ui.UpdateSinglePerk)=="function" and not self._perkOrig.UpdateSinglePerk then self._perkOrig.UpdateSinglePerk=ui.UpdateSinglePerk end
  if type(ui.Hide)=="function" and not self._perkOrig.Hide then self._perkOrig.Hide=ui.Hide end
  ui.Show=function(choices)
    if self._perkBlock then
      self._pendingChoices=choices
      self:_HidePerkFrameNow()
      return
    end
    return self._perkOrig.Show and self._perkOrig.Show(choices)
  end
  ui.UpdateSinglePerk=function(perkIndex,newPerkData)
    if self._perkBlock then
      self._pendingChoices=true
      self:_HidePerkFrameNow()
      return
    end
    return self._perkOrig.UpdateSinglePerk and self._perkOrig.UpdateSinglePerk(perkIndex,newPerkData)
  end
  ui.Hide=function(...)
    self._pendingChoices=nil
    return self._perkOrig.Hide and self._perkOrig.Hide(...)
  end
  self._perkHooked=true
end
function E:SyncPerkUI()
  local pr=EA.Profiles and EA.Profiles.GetActiveProfile and EA.Profiles:GetActiveProfile() or nil
  local want=pr and pr.automation and pr.automation.hidePerkFrameWhileRunning
  local run=self.state and self.state.enabled
  local block=want and run
  self._perkBlock=block and true or false
  if want then self:_HookPerkUI() end
  if self._perkBlock then
    self:_HidePerkFrameNow()
  else
    self:_ShowPerkFrameIfNeeded()
  end
end

function E:SetEnabled(v)
  self.state.enabled=v and true or false
  if not self.state.enabled then
    self.state.lastHash=nil
    self.state.rerollsThisOffer=0
  end
  self:SyncPerkUI()
end
function E:Tick()
  Run:MaybeReset()
  local offer,_=getCurrentOfferEx()
  if offer then
    self.state.lastOfferT=now()
    local parts={}
    for i=1,#offer do
      local c=offer[i]
      parts[i]=c and c.key or ""
    end
    local sig=table.concat(parts,"|")
    if self.state._offerSeen==nil then self.state._offerSeen={} end
    if self.state._offerSig~=sig then
      local exp=self.state._expectNewOffer
      if exp~="banish" then
        self.state._offerSeen={}
        self.state.rerollsThisOffer=0
      end
      self.state._offerSig=sig
      self.state._expectNewOffer=nil
    end
    local seen=self.state._offerSeen
    local new={}
    for i=1,#offer do
      local c=offer[i]
      if c and c.key and not seen[c.key] then
        seen[c.key]=true
        new[#new+1]=c
      end
    end
    if #new>0 then
      Log:RecordOffer(new)
    end
  end
  if not self.state.enabled then return end
  local pr=EA.Profiles:GetActiveProfile()
  if not canAct(pr) then return end
  local t=now()
  local d=actDelay(pr)
  if t-(tonumber(self.state.lastAct) or 0)<d then return end
  if not offer then return end
local res=decide(pr,offer)
  self.state.lastAct=t
  applyDecision(res,offer,pr)
end
function E:StartTicker()
  if self._ticker then return end
  self:_EnsureHooks()
  local f=CreateFrame("Frame")
  f:SetScript("OnUpdate",function(_,elapsed)
    E._acc=(E._acc or 0)+elapsed
    if E._acc<0.12 then return end
    E._acc=0
    local ok,err=pcall(function() E:Tick() end)
    if not ok then
      E:SetEnabled(false)
      chat("|cffff3333EchoArchitect error|r "..tostring(err))
    end
  end)
  self._ticker=f
end
