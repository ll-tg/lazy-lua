local Queue=require("ll-lua.queue"); local Metrics=require("ll-lua.metrics"); local Life=require("ll-lua.lifecycle"); local Transport=require("ll-lua.transport"); local json=require("ll-lua.json")
local M={}; M.__index=M
local function ct_equal(a,b) if type(a)~="string" or type(b)~="string" or #a~=#b then return false end; local x=0; for i=1,#a do x=x ~ a:byte(i) ~ b:byte(i) end; return x==0 end
function M.new(c) c=c or {}; local self=setmetatable({config=c,routes={},events={},metrics=Metrics.new(),life=Life.new(),queue=Queue.new(c.queue_capacity or 1024,c.spool_path,c.dead_letter_path),transport=nil,running=false,ready=false,workers=9},M); self.transport=Transport.new(self); return self end
function M:on_command(name,fn) self.routes["/"..name]=fn; return self end
function M:on_text(fn) self.routes.__text=fn; return self end
function M:on_event(name,fn) self.events[name]=fn; return self end
function M:on_reload(fn) self.life:on_reload(fn); return self end
function M:reload() self.life:reload(self); return true end
function M:call(method,params) self.metrics:inc("telegram_requests_total"); return self.transport:call(method,params) end
function M:dispatch(update)
  local msg=update.message or update.edited_message; local fn
  if update.callback_query then fn=self.events.callback_query elseif update.inline_query then fn=self.events.inline_query elseif msg and msg.text and msg.text:sub(1,1)=="/" then fn=self.routes[msg.text:match("^([^ ]+)")] elseif msg and msg.text then fn=self.routes.__text end
  if not fn then return true end
  local ctx={app=self,update=update,text=msg and msg.text or "",chat_id=msg and msg.chat and msg.chat.id or nil}
  function ctx:reply(text) return self.app:call("sendMessage",{chat_id=self.chat_id,text=text}) end
  function ctx:call(method,params) params=params or {}; if not params.chat_id then params.chat_id=self.chat_id end; return self.app:call(method,params) end
  fn(ctx); self.metrics:inc("updates_handled_total"); return true
end
function M:health() return {healthy=not self.transport.closed,ready=self.ready,queue_depth=self.queue:depth()} end
function M:metrics_text() self.metrics:set("queue_depth",self.queue:depth()); return self.metrics:text() end
function M:enqueue(u) local ok,e=self.queue:push(u); if ok then self.metrics:inc("updates_enqueued_total") else self.metrics:inc("updates_rejected_total") end; return ok,e end
function M:run() self.running=true; self.ready=true; if self.config.mode=="polling" then return self:run_polling() end; return self:run_webhook() end
function M:run_polling() local offset=0; while self.running do local updates=self.transport:poll(offset,self.config.poll_limit or 100,self.config.poll_timeout or 25); for _,u in ipairs(updates) do self:enqueue(u); offset=math.max(offset,(u.update_id or 0)+1); local ok,e=pcall(function() self:dispatch(u) end); if not ok then self.queue:fail(u,e,self.config.max_retries) end end end; return true end
function M:run_webhook() local ok,socket=pcall(require,"socket"); assert(ok,"webhook mode requires LuaSocket"); local srv=assert(socket.bind(self.config.listen_host or "127.0.0.1",self.config.listen_port or 8080)); srv:settimeout(0.5); while self.running do local c=srv:accept(); if c then c:settimeout(5); local req=c:receive("*l"); local path=req and req:match("^[A-Z]+ ([^ ]+)") or ""; local headers={}; repeat local line=c:receive("*l"); if line and line~="" then local k,v=line:match("^([^:]+):%s*(.*)"); if k then headers[k:lower()]=v end end until not line or line==""; local body=c:receive(tonumber(headers["content-length"]) or 0) or ""; local accepted=path==(self.config.webhook_path or "/telegram/webhook") and (not self.config.webhook_secret or ct_equal(headers["x-telegram-bot-api-secret-token"],self.config.webhook_secret)); local code=accepted and 202 or 403; if accepted then local u=json.decode(body); self:enqueue(u) end; c:send("HTTP/1.1 "..code.." OK\r\nContent-Length: 0\r\n\r\n"); c:close() end end; srv:close(); return true end
function M:stop() self.running=false; self.ready=false; self.transport:close(); return true end
return M
