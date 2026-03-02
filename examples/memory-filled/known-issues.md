# Known Issues — WeatherDash

## Active Bugs

### P0: NOAA API returns stale data on weekends
- NOAA's forecast endpoint (`/gridpoints/`) caches aggressively on weekends
- Workaround: skip NOAA comparison on Sat/Sun, use only OWM + WeatherAPI
- Issue #23 open, waiting for NOAA API team response
- **Don't try to fix by increasing request frequency** — this triggers 429s

### P1: Slack webhook URL expired (again)
- Webhook expires every ~90 days, no warning
- Current URL set 2026-02-15, expect expiry ~mid-May
- To refresh: Slack App Settings → Incoming Webhooks → Regenerate
- Update in `local/config.json` under `alerts.slack.webhook_url`

### P2: WeatherAPI returns Fahrenheit despite metric flag
- `units=metric` parameter ignored for `feelslike` field specifically
- Workaround in `src/collectors/weatherapi.py:87` — manual conversion
- Reported to WeatherAPI support, no response

## Fragile Points

1. **NOAA auth** — uses API key in header, not query param. Easy to misconfigure.
2. **OpenWeatherMap rate limit** — free tier is 60 calls/min. We use 45/min with buffer.
3. **Dashboard deploy** — Cloudflare Pages build hook URL in GitHub Actions secret. If deploys stop, check the webhook hasn't rotated.
4. **Timezone handling** — all times stored as UTC internally. Dashboard converts to user's local timezone via JS. Never store local times in the database.

## Resolved (Recent)

- ~~P0: Dashboard showing yesterday's data~~ — Fixed in PR #31. Cache invalidation was stale by 1 hour. Added `max-age=1800` header.
- ~~P1: Email alerts sending duplicates~~ — Fixed in PR #28. Dedup key was missing forecast date.
