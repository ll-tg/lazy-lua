local json = require("ll-lua.json")
local M = { URL = "https://raw.githubusercontent.com/ll-api/tg/main/api.min.json" }

-- Telegram methods are camelCase. Accept the idiomatic Lua snake_case spelling
-- while retaining canonical names for explicit callers.
function M.canonical_method(method)
  assert(type(method) == "string" and method ~= "", "API method must be a non-empty string")
  return (method:gsub("_([a-zA-Z])", string.upper))
end

local function curl(url)
  local p = assert(io.popen("curl -fsSL --max-time 20 " .. string.format("%q", url), "r"))
  local x = p:read("*a")
  local ok = p:close()
  assert(ok, "schema fetch failed")
  return x
end

function M.fetch_schema(url) return json.decode(curl(url or M.URL)) end
function M.index(schema)
  local out = { methods = {}, types = {} }
  local methods = schema.methods or schema
  for _, m in ipairs(methods) do
    if m.name then
      out.methods[m.name] = { name = m.name, description = m.description, params = {} }
      for _, p in ipairs(m.parameters or m.params or {}) do out.methods[m.name].params[p.name] = p end
    end
  end
  for _, t in ipairs(schema.types or {}) do if t.name then out.types[t.name] = t end end
  return out
end
function M.with_temporary_artifact(fn, schema)
  local path = os.tmpname()
  local index = M.index(schema or M.fetch_schema())
  local f = assert(io.open(path, "w")); f:write("return ", json.encode(index)); f:close()
  local ok, a, b = pcall(fn, path, index)
  os.remove(path)
  if not ok then error(a) end
  return a, b
end
return M
