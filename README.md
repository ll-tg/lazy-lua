# ll-lua

`ll-lua` is a language-only Telegram bot runtime for Lua 5.5. Bot source files are ordinary `.lua` files: there is no secondary bot language, dispatcher, plugin marketplace, or application database.

## Install

LuaRocks and Lua 5.5 are required. LuaSocket is the only runtime dependency for network transport.

```sh
luarocks install ll-lua
```

This repository is intentionally not published or pushed by the build process. For a local checkout:

```sh
luarocks make ll-lua-1.rockspec
```

## Quick start

```sh
export TELEGRAM_BOT_TOKEN='123:replace-me'
lua5.5 examples/echo.lua --mode polling
# or: lua5.5 bin/ll-lua examples/echo.lua --mode webhook --port 8080
```

A bot is a Lua module returning a table:

```lua
local bot = require("ll-lua")
local app = bot.new({ token = os.getenv("TELEGRAM_BOT_TOKEN"), mode = "polling" })
app:on_command("start", function(ctx) return ctx:reply("Hello") end)
app:on_text(function(ctx) return ctx:reply("Echo: " .. ctx.text) end)
app:run()
```

`new()` always creates the standard nine-runner capacity model. `workers` controls the active worker count but never changes the capacity ceiling. Handlers should be idempotent because delivery is at-least-once.

## Included capabilities

- Remote-only Telegram schema retrieval from `https://raw.githubusercontent.com/ll-api/tg/main/api.min.json`; parsing is in memory and generated API index artifacts are temporary.
- Webhook and long-polling lifecycle, including webhook secret validation, offset persistence, bounded body sizes, and graceful SIGTERM/SIGINT shutdown where the host exposes signals.
- Bounded queue with length-prefixed durable spool/replay, retry with bounded backoff, and a durable dead-letter queue.
- `ll-lua.storage.Store`, a narrow external developer-owned storage interface; no database is shipped.
- Nine-runner capacity model, reload hooks, health/readiness/Prometheus metrics, and TLS/mTLS configuration helpers.
- Direct Telegram API methods through schema-checked `app:call("sendMessage", params)` and convenience `ctx:reply()`.

## Configuration and deployment

Copy `config/config.lua.example`, keep tokens in the environment, and grant the process write access only to the spool/DLQ directories. See [`docs/SECURITY.md`](docs/SECURITY.md) and [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md). LuaSocket's HTTPS support uses LuaSec when available; terminate TLS at a trusted reverse proxy otherwise. The built-in listener is HTTP and is not a replacement for a production TLS terminator.

## Validation

```sh
make check
make test
```

The test suite uses a fake transport and does not contact Telegram or write schema files. The project does not claim distributed cluster coordination, native sandboxing, or full generated type coverage; these are outside a practical standard-library Lua runtime.
