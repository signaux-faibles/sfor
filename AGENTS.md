# AGENTS.md

## Cursor Cloud specific instructions

### Overview

Signaux Faibles On Rails (SFOR) is a Ruby on Rails 7.2 monolith (Ruby 3.2.2) for detecting companies in financial difficulty. It runs via Docker Compose with PostgreSQL and Redis.

### Running services

The development environment uses Docker Compose. See `README.md` for full setup commands. Key services:

| Service | Command | Port |
|---|---|---|
| PostgreSQL | `docker compose up -d db` | 5433 (host) → 5432 (container) |
| Redis | `docker compose up -d redis` | 6379 |
| Rails web (Puma + Sass + Prometheus) | `docker compose up web` | 3001 (host) → 3000 (container) |

### Gotchas

- **Postgres image version**: The `docker-compose.yml` uses `image: postgres` (latest). The latest tag (v18+) has a breaking change with data directory layout. Use a `docker-compose.override.yml` to pin `postgres:16-alpine` if you encounter startup failures. The CI uses `postgres:13`.
- **Database env vars**: The `.env` file must set `DATABASE_HOST=db`, `DATABASE_PORT=5432`, `DATABASE_NAME=signaux_faibles_v2`, `DATABASE_USERNAME=postgres`, `DATABASE_PASSWORD=password`. Copy `.env.example` and fill in these values.
- **Docker daemon**: In Cloud Agent VMs, Docker requires `fuse-overlayfs` storage driver and `iptables-legacy`. The update script handles Docker startup.
- **Seed data**: `rails db:seed` has a known issue where Company creation fails due to a column/association naming conflict on `department`. The user seed works if prerequisite seeds (actions, departments, geo_accesses, networks/entities/segments) complete first. Errors in company seeding do not block the user seed. To create a test user manually, use `rails runner` (see below).
- **Test user creation**: Password complexity requires 12+ chars with uppercase, lowercase, digit, and special char (e.g. `Test1234#dev`). User requires `entity`, `segment`, and `geo_access` associations which are created by seeds.

### Common commands (all run inside Docker)

```bash
# Lint
docker compose run --rm web bundle exec rubocop

# Security scan
docker compose run --rm web bundle exec brakeman -q -w2 --no-exit-on-warn

# Tests (requires test DB setup first)
docker compose run --rm -e RAILS_ENV=test web rails db:create db:migrate
docker compose run --rm -e RAILS_ENV=test web rails test

# Rails console
docker compose run --rm web rails console

# Database migrations
docker compose run --rm web rails db:migrate
```
