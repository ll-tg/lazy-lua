# Security

Tokens and webhook secrets are read from configuration or environment variables and are never logged. Run the bot as an unprivileged user, make spool and dead-letter files owner-only, and use a dedicated directory with restrictive permissions.

Webhook requests are bounded by `max_body_bytes`, checked against `X-Telegram-Bot-Api-Secret-Token` using a constant-time comparison, and rejected unless the configured path and method match. The queue is at-least-once: handlers must tolerate duplicate update IDs.

The built-in LuaSocket listener is plain HTTP. For HTTPS, use a reverse proxy with a current certificate. mTLS is represented by TLS helper configuration and should be enforced by that proxy; LuaSec integration is optional and not assumed by the core package.

The schema URL is fixed to the public upstream repository. It is fetched only when explicitly requested, parsed in memory, and never committed. Treat remote schema availability as a build/runtime dependency and pin a reviewed copy at the network perimeter if your deployment requires reproducibility.
