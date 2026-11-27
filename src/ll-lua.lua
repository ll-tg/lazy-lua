local Queue=require("ll-lua.queue"); local Metrics=require("ll-lua.metrics"); local Life=require("ll-lua.lifecycle"); local Transport=require("ll-lua.transport"); local Api=require("ll-lua.api"); local json=require("ll-lua.json")
local M={}

local function ct_equal(a,b) if type(a)~="string" or type(b)~="string" or #a~=#b then return false end; local x=0; for i=1,#a do x=x ~ a:byte(i) ~ b:byte(i) end; return x==0 end
local function event_name(key) return key:gsub("^on_","") end

function M.__index(self,key)
  local explicit=rawget(M,key)
  if explicit then return explicit end
  -- Route/event shorthand is deliberately method-shaped, so app:command_start(fn)
  -- and app:callback_query(fn) remain ordinary Lua source.
  if key:match("^command_[%w_]+$") then
    local name=key:sub(9)
    return function(app,fn) return app:on_command(name,fn) end
  end
  if key:match("^on_[%w_]+$") and key~="on_command" and key~="on_text" and key~="on_event" and key~="on_reload" then
    local name=event_name(key)
    return function(app,fn) return app:on_event(name,fn) end
  end
  -- No local schema is generated: normalize any direct Telegram method at call time.
  if key:match("^[a-z][A-Za-z0-9_]*$") then
    return function(app,params) return app:call(key,params) end
  end
end

function M.new(c) c=c or {}; local self=setmetatable({config=c,routes={},events={},metrics=Metrics.new(),life=Life.new(),queue=Queue.new(c.queue_capacity or 1024,c.spool_path,c.dead_letter_path),transport=nil,running=false,ready=false,workers=9},M); self.transport=Transport.new(self); return self end
function M:on_command(name,fn) name=name:gsub("^/",""); self.routes["/"..name]=fn; return self end
function M:command(name,fn) return self:on_command(name,fn) end
function M:on_text(fn) self.routes.__text=fn; return self end
function M:text(fn) return self:on_text(fn) end
function M:on_event(name,fn) self.events[event_name(name)]=fn; return self end
function M:event(name,fn) return self:on_event(name,fn) end
function M:on_callback_query(fn) return self:on_event("callback_query",fn) end
function M:on_inline_query(fn) return self:on_event("inline_query",fn) end
function M:callback_query(fn) return self:on_callback_query(fn) end
function M:inline_query(fn) return self:on_inline_query(fn) end
function M:on_reload(fn) self.life:on_reload(fn); return self end
function M:on_start(fn) self.life:on_start(fn); return self end
function M:on_stop(fn) self.life:on_stop(fn); return self end
function M:reload() self.life:reload(self); return true end
function M:call(method,params) self.metrics:inc("telegram_requests_total"); return self.transport:call(Api.canonical_method(method),params) end

local function context_for(app,update,msg)
  local source=msg or (update.callback_query and update.callback_query.message)
  local chat_id=source and source.chat and source.chat.id
  if not chat_id and update.inline_query and update.inline_query.from then chat_id=update.inline_query.from.id end
  local text=(msg and msg.text) or (update.callback_query and update.callback_query.data) or (update.inline_query and update.inline_query.query) or ""
  local ctx=setmetatable({app=app,update=update,text=text,chat_id=chat_id},{
    __index=function(c,key)
      if key=="reply" or key=="send_message" or key=="sendMessage" then return function(_,value) return c.app:call("sendMessage",type(value)=="table" and value or {chat_id=c.chat_id,text=value}) end end
      if key:match("^[a-z][A-Za-z0-9_]*$") then return function(_,params) params=params or {}; if params.chat_id==nil then params.chat_id=c.chat_id end; return c.app:call(key,params) end end
    end
  })
  function ctx:call(method,params) params=params or {}; if params.chat_id==nil then params.chat_id=self.chat_id end; return self.app:call(method,params) end
  return ctx
end

function M:dispatch(update)
  local msg=update.message or update.edited_message; local fn
  if update.callback_query then fn=self.events.callback_query elseif update.inline_query then fn=self.events.inline_query elseif msg and msg.text and msg.text:sub(1,1)=="/" then fn=self.routes[msg.text:match("^([^ ]+)")] elseif msg and msg.text then fn=self.routes.__text end
  if not fn then
    for name,handler in pairs(self.events) do if update[name] then fn=handler; break end end
  end
  if not fn then return true end
  fn(context_for(self,update,msg)); self.metrics:inc("updates_handled_total"); return true
end
function M:health() return {healthy=not self.transport.closed,ready=self.ready,queue_depth=self.queue:depth()} end
function M:metrics_text() self.metrics:set("queue_depth",self.queue:depth()); return self.metrics:text() end
function M:enqueue(u) local ok,e=self.queue:push(u); if ok then self.metrics:inc("updates_enqueued_total") else self.metrics:inc("updates_rejected_total") end; return ok,e end
function M:run() self.life:start(self); self.running=true; self.ready=true; if self.config.mode=="polling" then return self:run_polling() end; return self:run_webhook() end
function M:start() return self:run() end
function M:run_polling() local offset=0; while self.running do local updates=self.transport:poll(offset,self.config.poll_limit or 100,self.config.poll_timeout or 25); for _,u in ipairs(updates) do self:enqueue(u); offset=math.max(offset,(u.update_id or 0)+1); local ok,e=pcall(function() self:dispatch(u) end); if not ok then self.queue:fail(u,e,self.config.max_retries) end end end; return true end
function M:run_webhook() local ok,socket=pcall(require,"socket"); assert(ok,"webhook mode requires LuaSocket"); local srv=assert(socket.bind(self.config.listen_host or "127.0.0.1",self.config.listen_port or 8080)); srv:settimeout(0.5); while self.running do local c=srv:accept(); if c then c:settimeout(5); local req=c:receive("*l"); local path=req and req:match("^[A-Z]+ ([^ ]+)") or ""; local headers={}; repeat local line=c:receive("*l"); if line and line~="" then local k,v=line:match("^([^:]+):%s*(.*)"); if k then headers[k:lower()]=v end end until not line or line==""; local body=c:receive(tonumber(headers["content-length"]) or 0) or ""; local accepted=path==(self.config.webhook_path or "/telegram/webhook") and (not self.config.webhook_secret or ct_equal(headers["x-telegram-bot-api-secret-token"],self.config.webhook_secret)); local code=accepted and 202 or 403; if accepted then local u=json.decode(body); self:enqueue(u) end; c:send("HTTP/1.1 "..code.." OK\r\nContent-Length: 0\r\n\r\n"); c:close() end end; srv:close(); return true end
function M:stop() self.running=false; self.ready=false; self.life:stop(self); self.transport:close(); return true end
return M
