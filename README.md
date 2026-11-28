# ll-lua

Lua 5.5 Telegram bot runtime. Bot source files are ordinary `.lua` files.

## Install

Requirements: Lua 5.5 and LuaRocks.

```sh
luarocks install ll-lua
```

## Quick start

```sh
export TELEGRAM_BOT_TOKEN='123:replace-me'
lua5.5 examples/echo.lua --mode polling
```

```lua
local bot = require("ll-lua")
local app = bot.new({ token = os.getenv("TELEGRAM_BOT_TOKEN"), mode = "polling" })

app:command("start", function(ctx) return ctx:reply("Hello") end)
app:text(function(ctx) return ctx:reply("Echo: " .. ctx.text) end)
app:callback_query(function(ctx)
  return ctx:answer_callback_query({ callback_query_id = ctx.update.callback_query.id })
end)
app:run()
```

## Shorthand

`command`, `text`, `event`, `callback_query`, and `inline_query` register routes. `reply`, `send_message`, and `sendMessage` call Telegram `sendMessage`. Telegram methods accept camelCase or snake_case names. `start`, `stop`, and `reload` are lifecycle helpers.

See [`docs/API.md`](docs/API.md) for the complete native API reference.

## Test

```sh
make check
make test
```

Schema data is fetched from `https://raw.githubusercontent.com/ll-api/tg/main/api.min.json` at runtime and is not stored in the repository. Application data belongs in developer-owned storage.
