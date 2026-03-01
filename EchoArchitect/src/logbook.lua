local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.Logbook=EA.Logbook or {}
local L=EA.Logbook
local function merge(dst,src)
  if type(dst)~="table" then dst={} end
  if type(src)~="table" then return dst end
  for k,v in pairs(src) do
    if type(v)=="table" then
      if type(dst[k])~="table" then dst[k]={} end
      merge(dst[k],v)
    elseif dst[k]==nil then
      dst[k]=v
    end
  end
  return dst
end
L.defaults={
  version=1,
  totals={
    echoesSeen=0,
    picks=0,
    banishes=0,
    rerolls=0,
    runsCompleted=0,
  },
  raritySeen={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0},
	  qdistSel=2,
	  qdist={},
  perEcho={},
  sessionHighlights={fastest=0,slowest=0,xpPerHour=0,xpPerHourWall=0,xpSum=0,wallTimeSum=0,activeTimeSum=0,first={rare={sum=0,count=0},epic={sum=0,count=0},legendary={sum=0,count=0}}},
}
EchoArchitect_Logbook=EchoArchitect_Logbook or {}
local _bootlog=EchoArchitect_Logbook
merge(_bootlog,L.defaults)
_bootlog.perEcho=_bootlog.perEcho or {}

function L:Init()
  EchoArchitect_Logbook=EchoArchitect_Logbook or {}
  merge(EchoArchitect_Logbook,self.defaults)
  EchoArchitect_Logbook.perEcho=EchoArchitect_Logbook.perEcho or {}
  self:SeedFromDB()
  return EchoArchitect_Logbook
end


function L:SeedFromDB()
  local db=self:GetDB()
  if not db or not EchoArchitect or not EchoArchitect.DB then return end
  local list=EchoArchitect.DB:IterPerks(true)
  for i=1,#list do
    local e=list[i]
    local key=EchoArchitect.DB:MakeKey(e.spellId,e.quality)
    local t=db.perEcho[key]
    if type(t)~="table" then
      t={seen=0,picked=0,banished=0,quality=e.quality,spellId=e.spellId}
      db.perEcho[key]=t
    else
      t.quality=tonumber(t.quality or e.quality) or e.quality
      t.spellId=tonumber(t.spellId or e.spellId) or e.spellId
      if t.seen==nil then t.seen=0 end
      if t.picked==nil then t.picked=0 end
      if t.banished==nil then t.banished=0 end
    end
  end
end
function L:GetDB()
  return EchoArchitect_Logbook
end
local function ensureEcho(db,key)
  local t=db.perEcho[key]
  if type(t)~="table" then
    t={seen=0,picked=0,banished=0,quality=0,spellId=0,name="",icon="",tooltip=""}
    db.perEcho[key]=t
  end
  return t
end

local _tip
local function getIconNameFromPath(p)
  local s=tostring(p or "")
  if s=="" then return "" end
  local b=string.match(s,"[^\\]+$") or s
  b=string.gsub(b,"%.blp$","")
  b=string.gsub(b,"%.tga$","")
  b=string.gsub(b,"%.png$","")
  return b
end
local getSpellTooltipText
local function getSpellIconName(sid)
  if sid and sid>0 then
    local _,_,icon=GetSpellInfo and GetSpellInfo(sid)
    if (not icon or icon=="") then
      getSpellTooltipText(sid)
      _,_,icon=GetSpellInfo and GetSpellInfo(sid)
    end
    if (not icon or icon=="") and GetSpellTexture then icon=GetSpellTexture(sid) end
    return getIconNameFromPath(icon)
  end
  return ""
end
getSpellTooltipText=function(sid)
  if not sid or sid<=0 then return "" end
  if GetSpellDescription then
    local d=GetSpellDescription(sid)
    if d and d~="" then return tostring(d) end
  end
  if not _tip and CreateFrame then
    _tip=CreateFrame("GameTooltip","EA_LogTip",UIParent,"GameTooltipTemplate")
    _tip:SetOwner(UIParent,"ANCHOR_NONE")
  end
  if not _tip then return "" end
  _tip:ClearLines()
  _tip:SetHyperlink("spell:"..sid)
  local s=""
  for i=2,12 do
    local l=_G["EA_LogTipTextLeft"..i]
    if l then
      local t=l:GetText()
      if t and t~="" then
        if s~="" then s=s.."\n" end
        s=s..tostring(t)
      end
    end
  end
  return s
end
function L:RecordOffer(choices)
  local db=self:GetDB()
  if not db or type(choices)~="table" then return end
  for i=1,#choices do
    local c=choices[i]
    if c and c.key then
      db.totals.echoesSeen=(tonumber(db.totals.echoesSeen) or 0)+1
      local q=tonumber(c.quality or 0) or 0
      local Run=EA and EA.Run
	      local el=Run and Run.EchoLevel and Run:EchoLevel() or 0
	      if el>=2 and el<=80 then
	        db.qdist=db.qdist or {}
	        local qt=db.qdist[el]
	        if type(qt)~="table" then
	          qt={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0}
	          db.qdist[el]=qt
	        end
	        if q>=0 and q<=4 then qt[q]=(tonumber(qt[q]) or 0)+1 end
	      end
      if Run and Run.NoteFirstQuality then Run:NoteFirstQuality(q) end
      db.raritySeen[q]=(tonumber(db.raritySeen[q]) or 0)+1
      local e=ensureEcho(db,c.key)
      e.seen=(tonumber(e.seen) or 0)+1
      e.quality=q
      e.spellId=tonumber(c.spellId or 0) or 0
      if e.name=="" or e.icon=="" or e.tooltip=="" then
        local sid=e.spellId
        if e.name=="" then
          local nm=GetSpellInfo and select(1,GetSpellInfo(sid))
          if not nm or nm=="" then nm=c.name end
          e.name=tostring(nm or "")
        end
        if e.icon=="" then
          local ic=c.icon
          if not ic or ic=="" then ic=getSpellIconName(sid) end
          e.icon=tostring(ic or "")
        end
        if e.tooltip=="" then
          local tp=c.tooltip
          if not tp or tp=="" then tp=getSpellTooltipText(sid) end
          e.tooltip=tostring(tp or "")
        end
      end
      local _,cls=UnitClass and UnitClass("player")
      if cls and cls~="" then
        e.classes=e.classes or {}
        if not e.classes[cls] then e.classes[cls]=1 end
      end
    end
  end
end
function L:RecordPick(choice)
  local db=self:GetDB()
  if not db or not choice or not choice.key then return end
  db.totals.picks=(tonumber(db.totals.picks) or 0)+1
  local e=ensureEcho(db,choice.key)
  e.picked=(tonumber(e.picked) or 0)+1
end
function L:RecordBanish(choice)
  local db=self:GetDB()
  if not db or not choice or not choice.key then return end
  db.totals.banishes=(tonumber(db.totals.banishes) or 0)+1
  local e=ensureEcho(db,choice.key)
  e.banished=(tonumber(e.banished) or 0)+1
end
function L:RecordRerollPast(choices)
  local db=self:GetDB()
  if not db then return end
  db.totals.rerolls=(tonumber(db.totals.rerolls) or 0)+1
end
function L:RecordRunCompleted()
  local db=self:GetDB()
  if not db then return end
  db.totals.runsCompleted=(tonumber(db.totals.runsCompleted) or 0)+1
end

function L:RecordRunStart() end

function L:RecordSessionComplete(durationSec,xpGained,firstRare,firstEpic,firstLegendary,activeSec)
  local db=self:GetDB()
  if not db then return end
  db.sessionHighlights=db.sessionHighlights or {fastest=0,slowest=0,xpPerHour=0,xpPerHourWall=0,xpSum=0,wallTimeSum=0,activeTimeSum=0,first={rare={sum=0,count=0},epic={sum=0,count=0},legendary={sum=0,count=0}}}
  local h=db.sessionHighlights
  durationSec=tonumber(durationSec or 0) or 0
  xpGained=tonumber(xpGained or 0) or 0
  if durationSec>0 then
    local fastest=tonumber(h.fastest or 0) or 0
    local slowest=tonumber(h.slowest or 0) or 0
    if fastest==0 or durationSec<fastest then h.fastest=durationSec end
    if slowest==0 or durationSec>slowest then h.slowest=durationSec end
    h.xpSum=(tonumber(h.xpSum or 0) or 0)+xpGained
    h.wallTimeSum=(tonumber(h.wallTimeSum or 0) or 0)+durationSec
    activeSec=tonumber(activeSec or 0) or 0
    if activeSec>0 then
      h.activeTimeSum=(tonumber(h.activeTimeSum or 0) or 0)+activeSec
    end
    if (tonumber(h.wallTimeSum or 0) or 0)>0 then
      h.xpPerHourWall=(tonumber(h.xpSum or 0) or 0)/((tonumber(h.wallTimeSum or 0) or 0)/3600)
    end
    if (tonumber(h.activeTimeSum or 0) or 0)>0 then
      h.xpPerHour=(tonumber(h.xpSum or 0) or 0)/((tonumber(h.activeTimeSum or 0) or 0)/3600)
    else
      h.xpPerHour=h.xpPerHourWall
    end
  end
  local f=h.first or {}
  h.first=f
  f.rare=f.rare or {sum=0,count=0}
  f.epic=f.epic or {sum=0,count=0}
  f.legendary=f.legendary or {sum=0,count=0}
  firstRare=tonumber(firstRare or 0) or 0
  firstEpic=tonumber(firstEpic or 0) or 0
  firstLegendary=tonumber(firstLegendary or 0) or 0
  if firstRare>0 then f.rare.sum=(tonumber(f.rare.sum or 0) or 0)+firstRare f.rare.count=(tonumber(f.rare.count or 0) or 0)+1 end
  if firstEpic>0 then f.epic.sum=(tonumber(f.epic.sum or 0) or 0)+firstEpic f.epic.count=(tonumber(f.epic.count or 0) or 0)+1 end
  if firstLegendary>0 then f.legendary.sum=(tonumber(f.legendary.sum or 0) or 0)+firstLegendary f.legendary.count=(tonumber(f.legendary.count or 0) or 0)+1 end
end

function L:RecordFirstQuality(q,el)
  local db=self:GetDB()
  if not db then return end
  db.sessionHighlights=db.sessionHighlights or {fastest=0,slowest=0,xpPerHour=0,xpPerHourWall=0,xpSum=0,wallTimeSum=0,activeTimeSum=0,first={rare={sum=0,count=0},epic={sum=0,count=0},legendary={sum=0,count=0}}}
  local h=db.sessionHighlights
  local f=h.first or {}
  h.first=f
  f.rare=f.rare or {sum=0,count=0}
  f.epic=f.epic or {sum=0,count=0}
  f.legendary=f.legendary or {sum=0,count=0}
  q=tonumber(q or 0) or 0
  el=tonumber(el or 0) or 0
  if el<=0 then return end
  if q==2 then f.rare.sum=(tonumber(f.rare.sum or 0) or 0)+el f.rare.count=(tonumber(f.rare.count or 0) or 0)+1 end
  if q==3 then f.epic.sum=(tonumber(f.epic.sum or 0) or 0)+el f.epic.count=(tonumber(f.epic.count or 0) or 0)+1 end
  if q==4 then f.legendary.sum=(tonumber(f.legendary.sum or 0) or 0)+el f.legendary.count=(tonumber(f.legendary.count or 0) or 0)+1 end
end
function L:ComputeRarityOdds()
  local db=self:GetDB()
  if not db then return {} end
  local total=tonumber(db.totals.echoesSeen) or 0
  if total<=0 then return {[0]=0,[1]=0,[2]=0,[3]=0,[4]=0} end
  local out={}
  for q=0,4 do
    out[q]=(tonumber(db.raritySeen[q]) or 0)/total
  end
  return out
end
function L:ComputePickedByQuality()
  local db=self:GetDB()
  local out={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0}
  if not db or type(db.perEcho)~="table" then return out,0 end
  local total=0
  for _,v in pairs(db.perEcho) do
    local q=tonumber(v.quality or 0) or 0
    local p=tonumber(v.picked or 0) or 0
    if q>=0 and q<=4 then
      out[q]=out[q]+p
      total=total+p
    end
  end
  return out,total
end

function L:ComputeSeenByQuality()
  local db=self:GetDB()
  local out={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0}
  if not db or type(db.perEcho)~="table" then return out,0 end
  local total=0
  for _,v in pairs(db.perEcho) do
    local q=tonumber(v.quality or 0) or 0
    local s=tonumber(v.seen or 0) or 0
    if q>=0 and q<=4 then
      out[q]=out[q]+s
      total=total+s
    end
  end
  return out,total
end

function L:ComputeSeenByQualityAtEchoLevel(el)
  local db=self:GetDB()
  local out={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0}
  if not db or type(db.qdist)~="table" then return out,0 end
  el=tonumber(el or 0) or 0
  if el<2 or el>80 then return out,0 end
  local t=db.qdist[el]
  if type(t)~="table" then return out,0 end
  local total=0
  for q=0,4 do
    local v=tonumber(t[q] or 0) or 0
    out[q]=v
    total=total+v
  end
  return out,total
end

function L:BuildExport()
  local db=self:GetDB()
  local expAt=(date and date("%Y-%m-%d %H:%M:%S")) or ""
  local out={schema=3,addon=addonName or "EchoArchitect",exportedAt=expAt,perEcho={},totals={},raritySeen={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0},qdist={}}
  if not db or type(db.perEcho)~="table" then return out end
  if type(db.totals)=="table" then
    out.totals={
      echoesSeen=tonumber(db.totals.echoesSeen or 0) or 0,
      picks=tonumber(db.totals.picks or 0) or 0,
      banishes=tonumber(db.totals.banishes or 0) or 0,
      rerolls=tonumber(db.totals.rerolls or 0) or 0,
      runsCompleted=tonumber(db.totals.runsCompleted or 0) or 0,
    }
  end
  if type(db.raritySeen)=="table" then
    for q=0,4 do out.raritySeen[q]=tonumber(db.raritySeen[q] or 0) or 0 end
  end
  if type(db.qdist)=="table" then out.qdist=db.qdist end
  local tmp={}
  for k,v in pairs(db.perEcho) do
    local sid=tonumber(v.spellId or 0) or 0
    local q=tonumber(v.quality or 0) or 0
    local seen=tonumber(v.seen or 0) or 0
    local picked=tonumber(v.picked or 0) or 0
    local banished=tonumber(v.banished or 0) or 0
    if sid>0 and (seen>0 or picked>0 or banished>0) then
      local name=tostring(v.name or "")
      if name=="" then
        local nm=GetSpellInfo and select(1,GetSpellInfo(sid))
        name=tostring(nm or "")
      end
      local bn=getIconNameFromPath(v.icon)
      if bn=="" then bn=getSpellIconName(sid) end
      local tip=tostring(v.tooltip or "")
      if tip=="" then tip=getSpellTooltipText(sid) end

local classes={}
      if type(v.classes)=="table" then
        for cls,_ in pairs(v.classes) do
          local nm=cls
          if _G.LOCALIZED_CLASS_NAMES_MALE and _G.LOCALIZED_CLASS_NAMES_MALE[cls] then nm=_G.LOCALIZED_CLASS_NAMES_MALE[cls] end
          classes[#classes+1]=nm
        end
        table.sort(classes)
      end
      tmp[#tmp+1]={echoName=name or ("Spell "..tostring(sid)),echoQuality={qName=(q==0 and "Common") or (q==1 and "Uncommon") or (q==2 and "Rare") or (q==3 and "Epic") or (q==4 and "Legendary") or "Unknown",qId=q},echoSpellID=sid,echoIcon=bn,echoTooltip=tip,echoClasses=classes,AmountSeen=seen,AmountPicked=picked,AmountBanished=banished}
    end
  end
  table.sort(tmp,function(a,b)
    if a.echoQuality.qId~=b.echoQuality.qId then return a.echoQuality.qId>b.echoQuality.qId end
    if a.echoName~=b.echoName then return tostring(a.echoName)<tostring(b.echoName) end
    return tonumber(a.echoSpellID or 0)<tonumber(b.echoSpellID or 0)
  end)
  out.perEcho=tmp
  return out
end

function L:ImportExport(payload)
  if type(payload)~="table" then return false,"invalid" end
  local schema=tonumber(payload.schema or 0) or 0
  if schema<2 then return false,"version" end
  local db=self:GetDB()
  if not db then return false,"nodata" end
  db.perEcho=db.perEcho or {}
  db.totals=db.totals or {echoesSeen=0,picks=0,banishes=0,rerolls=0,runsCompleted=0}
  db.raritySeen=db.raritySeen or {[0]=0,[1]=0,[2]=0,[3]=0,[4]=0}
  db.qdist=db.qdist or {}

  local per=payload.perEcho
  local mergedEcho=0
  if type(per)=="table" then
    for i=1,#per do
      local e=per[i]
      if type(e)=="table" then
        local sid=tonumber(e.echoSpellID or 0) or 0
        local q=tonumber(e.echoQuality and e.echoQuality.qId or 0) or 0
        local seen=tonumber(e.AmountSeen or 0) or 0
        local picked=tonumber(e.AmountPicked or 0) or 0
        local banished=tonumber(e.AmountBanished or 0) or 0
        if sid>0 and q>=0 and q<=4 and (seen>0 or picked>0 or banished>0) then
          local key=EchoArchitect and EchoArchitect.DB and EchoArchitect.DB.MakeKey and EchoArchitect.DB:MakeKey(sid,q) or (tostring(sid)..":"..tostring(q))
          local dst=db.perEcho[key]
          if type(dst)~="table" then
            dst={seen=0,picked=0,banished=0,quality=q,spellId=sid,name="",icon="",tooltip=""}
            db.perEcho[key]=dst
          end
          dst.seen=(tonumber(dst.seen or 0) or 0)+seen
          dst.picked=(tonumber(dst.picked or 0) or 0)+picked
          dst.banished=(tonumber(dst.banished or 0) or 0)+banished
          dst.quality=q
          dst.spellId=sid
          if (dst.name=="" or dst.name==nil) and e.echoName then dst.name=tostring(e.echoName) end
          if (dst.icon=="" or dst.icon==nil) and e.echoIcon then dst.icon=tostring(e.echoIcon) end
          if (dst.tooltip=="" or dst.tooltip==nil) and e.echoTooltip then dst.tooltip=tostring(e.echoTooltip) end
          if type(e.echoClasses)=="table" then
            dst.classes=dst.classes or {}
            for j=1,#e.echoClasses do
              local cn=e.echoClasses[j]
              if cn and cn~="" and not dst.classes[cn] then dst.classes[cn]=1 end
            end
          end
          mergedEcho=mergedEcho+1
        end
      end
    end
  end

  if type(payload.totals)=="table" then
    db.totals.echoesSeen=(tonumber(db.totals.echoesSeen or 0) or 0)+(tonumber(payload.totals.echoesSeen or 0) or 0)
    db.totals.picks=(tonumber(db.totals.picks or 0) or 0)+(tonumber(payload.totals.picks or 0) or 0)
    db.totals.banishes=(tonumber(db.totals.banishes or 0) or 0)+(tonumber(payload.totals.banishes or 0) or 0)
    db.totals.rerolls=(tonumber(db.totals.rerolls or 0) or 0)+(tonumber(payload.totals.rerolls or 0) or 0)
    db.totals.runsCompleted=(tonumber(db.totals.runsCompleted or 0) or 0)+(tonumber(payload.totals.runsCompleted or 0) or 0)
  end
  if type(payload.raritySeen)=="table" then
    for q=0,4 do
      db.raritySeen[q]=(tonumber(db.raritySeen[q] or 0) or 0)+(tonumber(payload.raritySeen[q] or 0) or 0)
    end
  end

  local qd=payload.qdist
  local mergedQD=0
  if type(qd)=="table" then
    for el,t in pairs(qd) do
      local lvl=tonumber(el or 0) or 0
      if lvl>=2 and lvl<=80 and type(t)=="table" then
        local dst=db.qdist[lvl]
        if type(dst)~="table" then
          dst={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0}
          db.qdist[lvl]=dst
        end
        for q=0,4 do
          local addv=tonumber(t[q] or 0) or 0
          if addv~=0 then
            dst[q]=(tonumber(dst[q] or 0) or 0)+addv
            mergedQD=mergedQD+addv
          end
        end
      end
    end
  end
  return true,{mergedEcho=mergedEcho,mergedQDist=mergedQD}
end
function L:LeastSeenAvailable(showAll)
  if not EchoArchitect or not EchoArchitect.DB then return self:LeastSeen() end
  local db=self:GetDB()
  if not db then return nil end
  local list=EchoArchitect.DB:IterPerks(showAll==true)
  local leastKey,leastV=nil,nil
  for i=1,#list do
    local e=list[i]
    local key=EchoArchitect.DB:MakeKey(e.spellId,e.quality)
    local t=db.perEcho[key]
    local n=0
    if t then n=tonumber(t.seen or 0) or 0 end
    if leastV==nil or n<leastV then leastV=n leastKey=key end
  end
  return leastKey,leastV
end

function L:TopEchoBy(field)
  local db=self:GetDB()
  if not db then return nil end
  local bestKey,bestV=nil,-1
  for k,v in pairs(db.perEcho) do
    local n=tonumber(v[field] or 0) or 0
    if n>bestV then bestV=n bestKey=k end
  end
  return bestKey,bestV
end
function L:LeastSeen()
  local db=self:GetDB()
  if not db then return nil end
  local leastKey,leastV=nil,nil
  for k,v in pairs(db.perEcho) do
    local n=tonumber(v.seen or 0) or 0
    if leastV==nil or n<leastV then leastV=n leastKey=k end
  end
  return leastKey,leastV
end