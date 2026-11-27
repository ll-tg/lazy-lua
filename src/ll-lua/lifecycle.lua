local M={}; M.__index=M
function M.new() return setmetatable({hooks={}},M) end
function M:on_reload(fn) self.hooks[#self.hooks+1]=fn end
function M:reload(ctx) for _,fn in ipairs(self.hooks) do assert(fn(ctx)) end end
return M
