local json=require("ll-lua.json"); local M={}; M.__index=M
local function frame(f,x) f:write(string.pack(">I4",#x),x); f:flush() end
function M.new(cap,spool,dlq) local self=setmetatable({cap=cap or 1024,items={},spool=spool,dlq=dlq,retries={}},M); if spool then self:replay() end; return self end
function M:replay() if not self.spool then return end; local f=io.open(self.spool,"rb"); if not f then return end; while true do local h=f:read(4); if not h then break end; local n=string.unpack(">I4",h); local x=f:read(n); if x then self.items[#self.items+1]=json.decode(x) end end; f:close() end
function M:push(x) if #self.items>=self.cap then return nil,"queue full" end; self.items[#self.items+1]=x; if self.spool then local f=assert(io.open(self.spool,"ab")); frame(f,json.encode(x)); f:close() end; return true end
function M:pop() if #self.items==0 then return nil end; return table.remove(self.items,1) end
function M:fail(x,err,max) local id=x.update_id or tostring(x); local n=(self.retries[id] or 0)+1; self.retries[id]=n; if n>(max or 8) and self.dlq then local f=assert(io.open(self.dlq,"ab")); frame(f,json.encode({update=x,error=err,retries=n})); f:close(); return "dlq" end; return "retry" end
function M:depth() return #self.items end
return M
