local M={}; M.__index=M
function M.new() return setmetatable({counters={}, gauges={}},M) end
function M:inc(k,n) self.counters[k]=(self.counters[k] or 0)+(n or 1) end
function M:set(k,n) self.gauges[k]=n end
function M:text() local a={}; for k,v in pairs(self.counters) do a[#a+1]=k.." "..v end; for k,v in pairs(self.gauges) do a[#a+1]=k.." "..v end; table.sort(a); return table.concat(a,"\n").."\n" end
return M
