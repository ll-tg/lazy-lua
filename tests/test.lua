package.path="src/?.lua;src/?/init.lua;"..package.path
local ll=require("ll-lua"); local json=require("ll-lua.json"); local api=require("ll-lua.api"); local Queue=require("ll-lua.queue")
local function eq(a,b,msg) assert(a==b,msg or (tostring(a).." ~= "..tostring(b))) end

local x=json.decode('{"a":1,"ok":true,"items":["x"]}'); eq(x.a,1); eq(json.decode(json.encode(x)).items[1],"x")
local q=Queue.new(2); eq(q:push({update_id=1}),true); eq(q:push({update_id=2}),true); eq(q:push({update_id=3}),nil); eq(q:pop().update_id,1)

local app=ll.new({queue_capacity=4,token="test"}); local calls={}; app.transport.call=function(_,method,params) calls[#calls+1]={method=method,params=params}; return {ok=true} end
local command_text, text_value, callback_data, event_value
app:command("start",function(ctx) command_text=ctx.text; ctx:reply("hello") end)
app:text(function(ctx) text_value=ctx.text; ctx:send_message("echo") end)
app:callback_query(function(ctx) callback_data=ctx.text; ctx:answer_callback_query({callback_query_id="abc"}) end)
app:on_event("edited_channel_post",function(ctx) event_value=ctx.update.edited_channel_post.text end)
app:dispatch({update_id=1,message={text="/start",chat={id=7}}}); eq(command_text,"/start"); eq(calls[1].method,"sendMessage"); eq(calls[1].params.chat_id,7); eq(calls[1].params.text,"hello")
app:dispatch({update_id=2,message={text="plain",chat={id=7}}}); eq(text_value,"plain"); eq(calls[2].method,"sendMessage")
app:dispatch({update_id=3,callback_query={id="abc",data="clicked",message={chat={id=7}}}}); eq(callback_data,"clicked"); eq(calls[3].method,"answerCallbackQuery"); eq(calls[3].params.chat_id,7)
app:dispatch({update_id=4,edited_channel_post={text="changed"}}); eq(event_value,"changed")

app:send_message({chat_id=7,text="direct"}); eq(calls[4].method,"sendMessage")
app:sendMessage({chat_id=7,text="canonical"}); eq(calls[5].method,"sendMessage")
app:call("send_message",{chat_id=7,text="explicit snake"}); eq(calls[6].method,"sendMessage")
local started,stopped,reloaded=false,false,false
app:on_start(function() started=true end):on_stop(function() stopped=true end):on_reload(function() reloaded=true end)
app.life:start(app); app:reload(); app.life:stop(app); eq(started,true); eq(stopped,true); eq(reloaded,true)

local idx=api.index({methods={{name="sendMessage",parameters={{name="text"}}}}}); eq(idx.methods.sendMessage.params.text.name,"text"); eq(api.canonical_method("get_updates"),"getUpdates")
local path; api.with_temporary_artifact(function(p) path=p; local f=assert(io.open(p)); assert(f:read("*a"):match("sendMessage")); f:close() end,{methods={{name="sendMessage"}}}); assert(not io.open(path))
print("ok")
