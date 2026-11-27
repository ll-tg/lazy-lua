# Lua API

`ll-lua.new(config)` returns an app. Register `on_command(name, fn)`, `on_text(fn)`, or `on_event(name, fn)`. A handler receives a context with `update`, `text`, `chat_id`, `reply(text)`, and `call(method, params)`.

`app:run()` selects webhook or polling mode. `app:stop()` begins graceful shutdown. `app:on_reload(fn)` registers a lifecycle hook; `app:reload()` runs hooks without replacing the queue or transport. `app:health()` and `app:metrics_text()` support probes.

`ll-lua.api.fetch_schema()` retrieves and parses the upstream schema in memory. `api.index(schema)` returns method and parameter indexes. `api.with_temporary_artifact(fn)` creates a temporary typed index file, invokes `fn(path, index)`, and removes it even when `fn` fails.
