local M={}; M.__index=M
function M.new(app) return setmetatable({app=app,closed=false},M) end
function M:call(method,params) assert(self.app.config.token,"Telegram token is required"); local json=require("ll-lua.json"); local body=json.encode(params or {}); local cmd="curl -fsSL --max-time 30 -X POST "..string.format("%q", "https://api.telegram.org/bot"..self.app.config.token.."/"..method).." -H 'Content-Type: application/json' --data-binary "..string.format("%q",body); local p=assert(io.popen(cmd,"r")); local out=p:read("*a"); local ok=p:close(); assert(ok,"Telegram request failed"); return json.decode(out) end
function M:poll(offset,limit,timeout) local r=self:call("getUpdates",{offset=offset,limit=limit,timeout=timeout}); return r.result or {} end
function M:close() self.closed=true end
return M
