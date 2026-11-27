# Deployment

1. Install Lua 5.5, LuaRocks, LuaSocket, and optionally LuaSec.
2. Install the rock with `luarocks make ll-lua-1.rockspec`.
3. Create `/var/lib/ll-lua`, owned by the service user, for spool and dead-letter files.
4. Put Telegram credentials in an environment file readable only by the service user.
5. Run `bin/ll-lua examples/echo.lua --mode webhook` behind an HTTPS reverse proxy.
6. Configure Telegram's webhook URL and secret with the API client or `app:call("setWebhook", ...)`.

A polling deployment does not need an inbound listener. It persists the next `offset` before acknowledging a successful Telegram response and replays unacknowledged queued updates after restart. During shutdown, ingress stops first, workers drain within the configured grace period, and the transport closes last.

The runtime exposes `/healthz`, `/readyz`, and `/metrics` on the listener. Readiness is false until the queue and handler are initialized. Metrics use Prometheus text format.
