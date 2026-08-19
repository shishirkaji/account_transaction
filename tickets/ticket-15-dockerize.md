# Ticket 15 — Dockerize (OPTIONAL bonus, local stays primary)

**Status:** TODO
**Estimate:** ~20 min
**Depends on:** Tickets 10–12 (seed + endpoints needed for the proof)

## Goal
Package the app so a grader with Docker (but no Ruby) can run it with **one command** — while local dev (`bundle install` + `bin/rails server`) remains the documented primary path. Docker is a convenience, never a requirement.

## You'll know it worked when (deliverable)
```
docker compose up --build
```
then, in another terminal:
```
curl -s http://localhost:3000/up
# → 200

curl -s http://localhost:3000/accounts
# → 200, {"status":"SUCCESS","data":[5 seeded accounts...]}

curl -s -w "\nHTTP %{http_code}" -F "file=@MableBackEndCodeTest/mable_transactions.csv" http://localhost:3000/transaction_files
# → 201, SUCCESS, 4 complete
```

## Context
- Decision (locked 2026-08-19): Docker is **optional** — the rubric rewards domain logic, not infra; SQLite needs no services. The container exists to guarantee the Ruby 4.0.6 runtime for graders who don't have it
- README (Ticket 14) must present local as preferred, Docker as "alternative run method"

## Tasks
- [ ] Add `.dockerignore`: `.git`, `node_modules`, `log/`, `tmp/`, `storage/*.sqlite3`, `coverage/`
- [ ] Create `Dockerfile` (multi-stage):
  - base: `ruby:4.0.6` (if that tag doesn't exist, use the closest official Ruby 4.x tag and note it in the ticket)
  - install system deps needed by bundle (e.g. `build-essential`), copy `Gemfile` + `Gemfile.lock`, `bundle install`
  - copy the app, `EXPOSE 3000`
  - entrypoint: run `bin/rails db:migrate` then `bin/rails load_balances`, then start the server
- [ ] Create `docker-compose.yml`: one service, build from the Dockerfile, `ports: "3000:3000"`, **volume** `./storage:/app/storage` (SQLite file persists across container restarts)
- [ ] Add a `README.md` section **"Alternative: run with Docker"** — one `docker compose up --build` command, explicitly marked optional (local is preferred)
- [ ] Run the deliverable commands against the container; verify accounts are seeded and the upload works
- [ ] Restart the container and confirm balances persist (volume working)
- [ ] Confirm local dev still unaffected: `bundle exec rspec` green outside Docker

## Acceptance criteria
- [ ] `docker compose up --build` → health check 200, seeded accounts, upload 201 with 4 complete
- [ ] Data survives container restart (volume)
- [ ] README clearly marks Docker as optional
- [ ] Local `bundle exec rspec` + `bin/rubocop` still clean
- [ ] `.dockerignore` keeps the image lean (no .git, no logs, no DB files baked in)

## Files touched
- `Dockerfile` (new)
- `docker-compose.yml` (new)
- `.dockerignore` (new)
- `bin/docker-entrypoint` (new, if used)
- `README.md` (Docker section)

## Tests required
- None new — proven by the deliverable commands

## Definition of done
One command boots the whole app in a container with guaranteed runtime; local remains the documented, preferred path.

## Out of scope
- Any orchestration beyond one container (no Postgres swap, no multi-service)
- Making Docker required — it must never be
- CI/CD
