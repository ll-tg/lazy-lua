local M={}; M.__index=M
function M.new() return setmetatable({hooks={reload={},start={},stop={}}},M) end
function M:on_reload(fn) self.hooks.reload[#self.hooks.reload+1]=fn end
function M:on_start(fn) self.hooks.start[#self.hooks.start+1]=fn end
function M:on_stop(fn) self.hooks.stop[#self.hooks.stop+1]=fn end
function M:_run(kind,ctx) for _,fn in ipairs(self.hooks[kind]) do if fn(ctx)==false then error("lifecycle hook failed: "..kind) end end end
function M:start(ctx) self:_run("start",ctx) end
function M:stop(ctx) self:_run("stop",ctx) end
function M:reload(ctx) self:_run("reload",ctx) end
return M
