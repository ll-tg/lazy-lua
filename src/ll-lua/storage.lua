local M={}; M.__index=M
function M.new(impl) assert(impl and impl.get and impl.put and impl.delete,"storage requires get, put, delete"); return setmetatable({impl=impl},M) end
function M:get(k) return self.impl.get(k) end
function M:put(k,v) return self.impl.put(k,v) end
function M:delete(k) return self.impl.delete(k) end
return M
