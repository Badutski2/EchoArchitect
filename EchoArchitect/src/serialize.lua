local addonName=...
EchoArchitect=EchoArchitect or {}
local EA=EchoArchitect
EA.Serialize=EA.Serialize or {}
local S=EA.Serialize
local function esc(s)
  s=string.gsub(s,"\\","\\\\")
  s=string.gsub(s,"\n","\\n")
  s=string.gsub(s,"\r","\\r")
  s=string.gsub(s,"\t","\\t")
  s=string.gsub(s,'"','\\"')
  return s
end
local function keyOrder(t)
  local nk,sk={},{}
  for k in pairs(t) do
    if type(k)=="number" then table.insert(nk,k) else table.insert(sk,k) end
  end
  table.sort(nk)
  table.sort(sk)
  local out={}
  for i=1,#nk do out[#out+1]=nk[i] end
  for i=1,#sk do out[#out+1]=sk[i] end
  return out
end
local function ser(v,depth)
  local tv=type(v)
  if tv=="nil" then return "nil" end
  if tv=="number" then
    if v~=v then return "0" end
    if v==math.huge or v==-math.huge then return "0" end
    return tostring(v)
  end
  if tv=="boolean" then return v and "true" or "false" end
  if tv=="string" then return '"'..esc(v)..'"' end
  if tv~="table" then return "nil" end
  if depth>50 then return "{}" end
  local parts={}
  local keys=keyOrder(v)
  for i=1,#keys do
    local k=keys[i]
    local kk
    if type(k)=="number" then kk='['..tostring(k)..']' else kk='["'..esc(k)..'"]' end
    parts[#parts+1]=kk..'='..ser(v[k],depth+1)
  end
  return '{'..table.concat(parts,',')..'}'
end
local function serPretty(v,depth,indent)
  local tv=type(v)
  if tv=="nil" then return "nil" end
  if tv=="number" then
    if v~=v then return "0" end
    if v==math.huge or v==-math.huge then return "0" end
    return tostring(v)
  end
  if tv=="boolean" then return v and "true" or "false" end
  if tv=="string" then return '"'..esc(v)..'"' end
  if tv~="table" then return "nil" end
  if depth>50 then return "{}" end
  local keys=keyOrder(v)
  if #keys==0 then return "{}" end
  local ind=string.rep(indent,depth)
  local ind2=string.rep(indent,depth+1)
  local parts={"{\n"}
  for i=1,#keys do
    local k=keys[i]
    local kk
    if type(k)=="number" then kk='['..tostring(k)..']' else kk='["'..esc(k)..'"]' end
    parts[#parts+1]=ind2..kk.."="..serPretty(v[k],depth+1,indent)
    if i<#keys then parts[#parts+1]=",\n" else parts[#parts+1]="\n" end
  end
  parts[#parts+1]=ind.."}"
  return table.concat(parts,"")
end
function S:Export(tbl)
  if type(tbl)~="table" then return "" end
  return "EA1:"..serPretty(tbl,0,"  ")
end
function S:Import(str)
  if type(str)~="string" then return nil,"invalid" end
  if string.sub(str,1,4)~="EA1:" then return nil,"version" end
  local body=string.sub(str,5)
  if body=="" then return nil,"empty" end
  local f,err=loadstring("return "..body)
  if not f then return nil,err end
  local ok,res=pcall(f)
  if not ok then return nil,res end
  if type(res)~="table" then return nil,"notable" end
  return res,nil
end
