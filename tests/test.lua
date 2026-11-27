package.path="src/?.lua;src/?/init.lua;"..package.path
local ll=require("ll-lua"); local json=require("ll-lua.json"); local api=require("ll-lua.api"); local Queue=require("ll-lua.queue")
local function eq(a,b,msg) assert(a==b,msg or (tostring(a).." ~= "..tostring(b))) end
local x=json.decode('{"a":1,"ok":true,"items":["x"]}'); eq(x.a,1); eq(json.decode(json.encode(x)).items[1],"x")
local q=Queue.new(2); eq(q:push({update_id=1}),true); eq(q:push({update_id=2}),true); eq(q:push({update_id=3}),nil); eq(q:pop().update_id,1)
local app=ll.new({queue_capacity=4}); local got; app:on_command("start",function(ctx) got=ctx.text end); app:dispatch({update_id=1,message={text="/start",chat={id=7}}}); eq(got,"/start"); eq(app:health().ready,false)
local idx=api.index({methods={{name="sendMessage",parameters={{name="text"}}}}}); eq(idx.methods.sendMessage.params.text.name,"text")
local path; api.with_temporary_artifact(function(p) path=p; local f=assert(io.open(p)); assert(f:read("*a"):match("sendMessage")); f:close() end,{methods={{name="sendMessage"}}}); assert(not io.open(path))
print("ok")
