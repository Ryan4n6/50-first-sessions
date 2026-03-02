# File Map — Quick Reference

<!-- One-line description of every significant file. -->
<!-- Claude uses this to know where to look without reading every file. -->

## Entry Points
<!-- Main scripts and CLI commands -->
<!-- Example: - `scripts/build.sh` — Production build pipeline -->

## Core Logic
<!-- Business logic, models, core algorithms -->
<!-- Example: - `src/models/user.py` — User model with auth methods -->

## Infrastructure
<!-- CI/CD, deployment, configuration -->
<!-- Example: - `.github/workflows/deploy.yml` — Auto-deploy on push to main -->

## Config & Secrets
<!-- Where configuration lives. Mark PII sensitivity. -->
<!-- Example: - `config.json` — ALL SECRETS (gitignored). API keys, DB credentials -->
<!-- Example: - `config.example.json` — Schema template (no real values) -->

## Tests
<!-- Test organization -->
<!-- Example: - `tests/` — pytest suite, mock at _fetch() boundary -->
