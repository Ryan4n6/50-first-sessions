# Project Memory — WeatherDash

## What This Is

Real-time weather dashboard that aggregates data from 3 weather APIs (OpenWeatherMap, WeatherAPI, NOAA), detects forecast disagreements, and sends alerts via email and Slack.

## Architecture

```
Collect → Normalize → Compare → Alert → Dashboard
```

- **Collect**: API clients for each weather source (`src/collectors/`)
- **Normalize**: Raw API responses → unified `Forecast` model (`src/normalize.py`)
- **Compare**: Cross-reference forecasts, flag disagreements (`src/analysis/`)
- **Alert**: Email + Slack notifications for severe disagreements (`src/alerts/`)
- **Dashboard**: Static HTML generated from latest data (`src/dashboard/`)

## Key Conventions

- All API clients mock at `_fetch()` boundary (not `urllib`)
- Tests use sequential `side_effect` for multi-step auth chains
- Config in `local/config.json` (gitignored) — use `config.example.json` as template
- Branch workflow: always PR to main. Prefixes: `feature/`, `fix/`, `refactor/`

## Current State (2026-03-01)

- 3 collectors working (OpenWeatherMap, WeatherAPI, NOAA)
- Dashboard deployed to Cloudflare Pages
- Alert system working for email, Slack webhook needs refresh
- 847 tests, all passing
- GitHub Actions runs daily at 6 AM ET

## Quick Reference

| What | Where |
|------|-------|
| API clients | `src/collectors/owm.py`, `weatherapi.py`, `noaa.py` |
| Normalization | `src/normalize.py` — raw data → `Forecast` model |
| Comparison engine | `src/analysis/compare.py` |
| Alert dispatch | `src/alerts/dispatch.py` |
| Dashboard generator | `src/dashboard/build.py` |
| Config loader | `src/config.py` → reads `local/config.json` |
| Tests | `tests/` — 847 tests, ~8s to run |

See `known-issues.md` for bugs and fragile points.
See `file-map.md` for full file structure.
See `next-session-pickup.md` for what to work on next.
