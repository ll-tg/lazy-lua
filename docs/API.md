# Lua API

`ll-lua.new(config)` returns an app. The explicit registration APIs are
`on_command(name, fn)`, `on_text(fn)`, and `on_event(name, fn)`. Native
shorthand aliases are `command(name, fn)`, `text(fn)`, `event(name, fn)`,
`callback_query(fn)`, and `inline_query(fn)`. Named update events can be
registered with `event("callback_query", fn)` or any update key supported by
the runtime.

```lua
local app = require("ll-lua").new({ token = os.getenv("TELEGRAM_BOT_TOKEN") })
app:command("start", function(ctx) ctx:send_message("Hello") end)
app:text(function(ctx) ctx:sendMessage(ctx.text) end)
app:callback_query(function(ctx) ctx:answer_callback_query({ callback_query_id = ctx.update.callback_query.id }) end)
app:inline_query(function(ctx) ctx:answer_inline_query({ inline_query_id = ctx.update.inline_query.id, results = {} }) end)
app:send_message({ chat_id = 7, text = "Hello" })
app:start()
```

A handler receives a context with `update`, `text`, and `chat_id`.
`ctx:reply(text)`, `ctx:send_message(text)`, and `ctx:sendMessage(text)` all
map to `sendMessage`; `ctx:call(method, params)` remains available. Direct
app methods accept either canonical Telegram names or snake_case, so
`app:send_message(params)` and `app:sendMessage(params)` are equivalent.

`app:run()` selects webhook or polling mode; `app:start()` is its lifecycle
shorthand. `app:stop()` begins graceful shutdown. `app:on_start(fn)`,
`app:on_stop(fn)`, and `app:on_reload(fn)` register lifecycle hooks;
`app:reload()` runs reload hooks without replacing the queue or transport.
`app:health()` and `app:metrics_text()` support probes.

`ll-lua.api.fetch_schema()` retrieves and parses the upstream schema in memory. `api.index(schema)` returns method and parameter indexes. `api.with_temporary_artifact(fn)` creates a temporary typed index file, invokes `fn(path, index)`, and removes it even when `fn` fails.
