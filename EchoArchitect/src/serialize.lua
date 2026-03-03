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
  local i=1
  local n=string.len(body)
  local function skipWS()
    while i<=n do
      local c=string.sub(body,i,i)
      if c==" " or c=="\n" or c=="\r" or c=="\t" then
        i=i+1
      else
        break
      end
    end
  end
  local function parseString()
    if string.sub(body,i,i)~='"' then return nil,"string" end
    i=i+1
    local out={}
    while i<=n do
      local c=string.sub(body,i,i)
      if c=='"' then
        i=i+1
        return table.concat(out,""),nil
      elseif c=="\\" then
        i=i+1
        local e=string.sub(body,i,i)
        if e=="n" then out[#out+1]="\n"
        elseif e=="r" then out[#out+1]="\r"
        elseif e=="t" then out[#out+1]="\t"
        elseif e=='"' then out[#out+1]='"'
        elseif e=="\\" then out[#out+1]="\\"
        else return nil,"escape" end
        i=i+1
      else
        out[#out+1]=c
        i=i+1
      end
    end
    return nil,"unterminated"
  end
  local function parseNumber()
    local s=i
    if string.sub(body,i,i)=="-" then i=i+1 end
    local digits=false
    while i<=n do
      local c=string.sub(body,i,i)
      if c>="0" and c<="9" then digits=true i=i+1 else break end
    end
    if string.sub(body,i,i)=="." then
      i=i+1
      while i<=n do
        local c=string.sub(body,i,i)
        if c>="0" and c<="9" then digits=true i=i+1 else break end
      end
    end
    if not digits then return nil,"number" end
    local txt=string.sub(body,s,i-1)
    local num=tonumber(txt)
    if num==nil then return nil,"number" end
    if num~=num or num==math.huge or num==-math.huge then num=0 end
    return num,nil
  end
  local parseValue
  local function parseKey()
    skipWS()
    if string.sub(body,i,i)~="[" then return nil,"keyopen" end
    i=i+1
    skipWS()
    local kc=string.sub(body,i,i)
    local key,err
    if kc=='"' then
      key,err=parseString()
      if err then return nil,err end
    else
      key,err=parseNumber()
      if err then return nil,err end
    end
    skipWS()
    if string.sub(body,i,i)~="]" then return nil,"keyclose" end
    i=i+1
    skipWS()
    if string.sub(body,i,i)~="=" then return nil,"keyeq" end
    i=i+1
    return key,nil
  end
  local function parseTable(depth)
    if depth>50 then return {},nil end
    skipWS()
    if string.sub(body,i,i)~="{" then return nil,"tableopen" end
    i=i+1
    local out={}
    skipWS()
    if string.sub(body,i,i)=="}" then i=i+1 return out,nil end
    while i<=n do
      local key,err=parseKey()
      if err then return nil,err end
      local val
      val,err=parseValue(depth+1)
      if err then return nil,err end
      out[key]=val
      skipWS()
      local c=string.sub(body,i,i)
      if c=="," then
        i=i+1
      elseif c=="}" then
        i=i+1
        return out,nil
      else
        return nil,"tabledelim"
      end
    end
    return nil,"tableeof"
  end
  parseValue=function(depth)
    skipWS()
    local c=string.sub(body,i,i)
    if c=="{" then return parseTable(depth) end
    if c=='"' then return parseString() end
    if c=="-" or (c>="0" and c<="9") then return parseNumber() end
    if string.sub(body,i,i+3)=="true" then i=i+4 return true,nil end
    if string.sub(body,i,i+4)=="false" then i=i+5 return false,nil end
    if string.sub(body,i,i+2)=="nil" then i=i+3 return nil,nil end
    return nil,"value"
  end
  local res,err=parseValue(0)
  if err then return nil,err end
  skipWS()
  if i<=n then return nil,"trailing" end
  if type(res)~="table" then return nil,"notable" end
  return res,nil
end
