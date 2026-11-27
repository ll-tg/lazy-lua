local M = {}

local function skip(s, i)
  return s:find("%S", i) or (#s + 1)
end

local function parse_value(s, i)
  i = skip(s, i)
  local c = s:sub(i, i)
  if c == '"' then
    local out, j = {}, i + 1
    while j <= #s do
      local x = s:sub(j, j)
      if x == '"' then
        return table.concat(out), j + 1
      end
      if x == "\\" then
        local e = s:sub(j + 1, j + 1)
        local map = { ['"'] = '"', ['\\'] = '\\', ['/'] = '/', b = '\b', f = '\f', n = '\n', r = '\r', t = '\t' }
        if e == 'u' then
          local h = s:sub(j + 2, j + 5)
          out[#out + 1] = utf8.char(tonumber(h, 16))
          j = j + 6
        else
          out[#out + 1] = map[e] or error("invalid JSON escape")
          j = j + 2
        end
      else
        out[#out + 1] = x
        j = j + 1
      end
    end
    error("unterminated JSON string")
  elseif c == '{' then
    local t, j = {}, skip(s, i + 1)
    if s:sub(j, j) == '}' then return t, j + 1 end
    while true do
      local k
      k, j = parse_value(s, j)
      j = skip(s, j)
      assert(s:sub(j, j) == ':', "expected colon")
      local v
      v, j = parse_value(s, skip(s, j + 1))
      t[k] = v
      j = skip(s, j)
      if s:sub(j, j) == '}' then return t, j + 1 end
      assert(s:sub(j, j) == ',', "expected comma")
      j = skip(s, j + 1)
    end
  elseif c == '[' then
    local t, j = {}, skip(s, i + 1)
    if s:sub(j, j) == ']' then return t, j + 1 end
    while true do
      local v
      v, j = parse_value(s, j)
      t[#t + 1] = v
      j = skip(s, j)
      if s:sub(j, j) == ']' then return t, j + 1 end
      assert(s:sub(j, j) == ',', "expected comma")
      j = skip(s, j + 1)
    end
  else
    local w = s:match("^[%-%w%.]+", i)
    assert(w, "invalid JSON value")
    if w == "true" then return true, i + #w end
    if w == "false" then return false, i + #w end
    if w == "null" then return nil, i + #w end
    return tonumber(w), i + #w
  end
end

function M.decode(s)
  local v, i = parse_value(s, 1)
  assert(skip(s, i) > #s, "trailing JSON")
  return v
end

function M.encode(v)
  local t = type(v)
  if t == "nil" then return "null" end
  if t == "boolean" or t == "number" then return tostring(v) end
  if t == "string" then
    return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '"'
  end
  if t == "table" then
    local a, n = {}, 0
    for k in pairs(v) do if type(k) == "number" then n = math.max(n, k) end end
    if n > 0 then
      for i = 1, n do a[#a + 1] = M.encode(v[i]) end
      return '[' .. table.concat(a, ',') .. ']'
    end
    for k, x in pairs(v) do a[#a + 1] = M.encode(tostring(k)) .. ':' .. M.encode(x) end
    return '{' .. table.concat(a, ',') .. '}'
  end
  error("unsupported JSON type")
end

return M
