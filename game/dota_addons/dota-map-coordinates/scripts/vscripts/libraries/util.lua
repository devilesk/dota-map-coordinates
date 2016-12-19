function istable(t)
  return type(t) == "table"
end

function isnumber(t)
  return type(t) == "number"
end

function isfunction(t)
  return type(t) == "function"
end

function shallowcopy(orig)
  local copy
  if istable(orig) then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function deepcopy(orig)
  local copy
  if istable(orig) then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepcopy(orig_key)] = deepcopy(orig_value)
    end
    setmetatable(copy, deepcopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function reversetable(t)
  assert(istable(t), "reversetable() expected a table, got nil")
  for i = 1, math.ceil(#t/2) do
    t[i], t[#t-i+1] = t[#t-i+1], t[i]
  end
  return t
end

function inverttable(t)
  assert(istable(t), "inverttable() expected a table, got nil")
  local s = {}
  for k, v in pairs(t) do
    s[v] = k
  end
  return s
end

function identity(a)
  return a
end

function equals(a, b, k)
  if k == nil then
    return a == b
  else
    return a[k] == b[k]
  end
end

function tableequals(a, b, f)
  assert(istable(a), "tableequals() first argument is not a table")
  assert(istable(b), "tableequals() second argument is not a table")
  local f = f or equals
  assert(isfunction(f), "tableequals() third argument is not a function")
  if tablelength(a) ~= tablelength(b) then
    return false
  end
  return all(function (v, k, a) 
    return f(v, b[k])
  end, a)
end

function tablelength(t)
  assert(istable(t), "tablelength() expected a table, got nil")
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function shuffletable(t)
  local rand = math.random 
  assert(istable(t), "shuffletable() expected a table, got nil")
  local iterations = #t
  local j
  for i = iterations, 2, -1 do
      j = rand(i)
      t[i], t[j] = t[j], t[i]
  end
  return t
end

function any(f, t, ...)
  assert(isfunction(f), "any() first argument not a function")
  assert(istable(t), "any() second argument not a table")
  for k, v in pairs(t) do
    if f(v, k, t, ...) then return true end
  end
  return false
end

function all(f, t, ...)
  assert(isfunction(f), "all() first argument not a function")
  assert(istable(t), "all() second argument not a table")
  for k, v in pairs(t) do
    if not f(v, k, t, ...) then return false end
  end
  return true
end

function slice(tbl, i, j)
  assert(istable(tbl), "slice() first argument not a table")
  if i == nil then i = 1 end
  if j == nil then j = #tbl end
  assert(isnumber(i), "slice() second argument not a number")
  assert(isnumber(j), "slice() third argument not a number")
  j = math.min(j, #tbl)
  local res = {}
  for k = i,j do
    res[k-i+1] = tbl[k]
  end
  return res
end

function tablefind(o, tbl, pos, ...)
  local func = o
  if not isfunction(o) then
    func = function (item)
      return equals(o, item)
    end
  end
  assert(istable(tbl), "tablefind() second argument not a table")
  if pos == nil then
    for k, v in pairs(tbl) do
      if func(v, k, tbl, ...) then
        return v, k
      end
    end
  else
    assert(isnumber(pos), "tablefind() third argument not a number")
    for k, v in ipairs(tbl) do
      if func(v, k, tbl, ...) and k > pos then
        return v, k
      end
    end
  end
  return nil, nil
end

function count(o, tbl, pos, ...)
  local func = o
  if not isfunction(o) then
    func = function (item)
      return equals(o, item)
    end
  end
  assert(istable(tbl), "count() second argument not a table")
  local c = 0
  if pos == nil then
    for k, v in pairs(tbl) do
      if func(v, k, tbl, ...) then
        c = c + 1
      end
    end
  else
    assert(isnumber(pos), "count() third argument not a number")
    for k, v in ipairs(tbl) do
      if func(v, k, tbl, ...) and k > pos then
        c = c + 1
      end
    end
  end
  return c
end

function contains(o, tbl)
  assert(istable(tbl), "contains() second argument not a table")
  local v, k = tablefind(o, tbl)
  return v ~= nil and k ~= nil
end

function tableextract(tbl, comp, f, ...) -- extracts value from a list
  local retval
  local retkey
  local f = f or identity
  assert(isfunction(f), "tableextract() third argument not a function")
  for k, v in pairs(tbl) do
    if not retval then
      retval = f(v, ...)
    else
      local v = f(v, ...)
      local c = comp(retval, v)
      retval, retkey = c and retval or v, c and retkey or k
    end
  end
  return retval, retkey
end

function tablemin(tbl, f, ...)
  assert(isfunction(f), "tablemin() second argument not a function")
  return tableextract(tbl, function(n,m) return n < m end, f, ...)
end

function tablemax(tbl, f, ...)
  assert(isfunction(f), "tablemax() second argument not a function")
  return tableextract(tbl, function(n,m) return n > m end, f, ...)
end

function split(str, pat)
  local t = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pat
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
  table.insert(t,cap)
    end
    last_end = e+1
    s, e, cap = str:find(fpat, last_end)
  end
  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end
  return t
end

function PrintTable(t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 0

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end

print( "util.lua is loaded." )