local ll = require("ll-lua")
local app = ll.new({
  token = os.getenv("TELEGRAM_BOT_TOKEN"),
  mode = "polling",
  spool_path = os.getenv("LL_LUA_SPOOL"),
})

app:on_command("start", function(ctx)
  return ctx:reply("Hello from Lua 5.5")
end)

app:on_text(function(ctx)
  return ctx:reply("Echo: " .. ctx.text)
end)

return app
