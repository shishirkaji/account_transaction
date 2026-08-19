# Ticket 01 — Wire SQLite into the app (gem + AR + database.yml)

**Status:** ✅ DONE (2026-08-19) — all acceptance criteria verified. Note: adapter_name prints `SQLite` (Rails 8.1 naming), DB file created lazily on first query. RSpec boots clean, 0 examples.
**Estimate:** ~15 min
**Depends on:** nothing

## Goal
The app can boot with ActiveRecord loaded and connect to a real SQLite database. After this ticket, the database exists and works — no further ticket needed to prove it.

## You'll know it worked when (deliverable)
```
bin/rails runner "puts ActiveRecord::Base.connection.adapter_name"
```
prints `sqlite3`, and `storage/development.sqlite3` exists on disk.

## Tasks
- [ ] Add `gem "sqlite3"` to `Gemfile` (main gem list, after `gem "thruster"`)
- [ ] `bundle install`
- [ ] In `config/application.rb`, uncomment `require "active_record/railtie"` (leave all other commented requires alone)
- [ ] Create `config/database.yml`:
  ```yaml
  default: &default
    adapter: sqlite3
    pool: 5
    timeout: 5000

  development:
    <<: *default
    database: storage/development.sqlite3

  test:
    <<: *default
    database: storage/test.sqlite3
  ```
- [ ] Create `storage/` directory with a `.keep` file
- [ ] Update `.gitignore`: add `/storage/*` and `!/storage/.keep`

## Acceptance criteria
- [ ] `bundle check` exits 0 and `Gemfile.lock` contains `sqlite3`
- [ ] `bin/rails runner "puts defined?(ActiveRecord)"` → `constant`
- [ ] `bin/rails runner "puts ActiveRecord::Base.connection.adapter_name"` → `sqlite3`
- [ ] `RAILS_ENV=test bin/rails runner "puts ActiveRecord::Base.connection.adapter_name"` → `sqlite3`
- [ ] `storage/development.sqlite3` exists after first connection
- [ ] `git status` shows `storage/.keep` tracked, no `*.sqlite3` files untracked
- [ ] App boots: `bin/rails runner "puts 'ok'"` → `ok`

## Files touched
- `Gemfile`, `Gemfile.lock`
- `config/application.rb`
- `config/database.yml` (new)
- `storage/.keep` (new)
- `.gitignore`

## Tests required
- None — but RSpec must still boot (it may warn about AR; Ticket 02 fixes that). Run `bundle exec rspec` and note the result in the ticket.

## Definition of done
SQLite is wired and provably working in both environments. Nothing depends on a later ticket.

## Out of scope
- RSpec/AR wiring in `spec/rails_helper.rb` (Ticket 02)
- Migrations and models (Ticket 03+)
