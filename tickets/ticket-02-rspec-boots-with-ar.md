# Ticket 02 — Make RSpec boot with ActiveRecord

**Status:** TODO
**Estimate:** ~10 min
**Depends on:** Ticket 01 (SQLite wired — verified)

## Goal
The test suite boots the app with ActiveRecord fully enabled. After this ticket, `bundle exec rspec` runs green with AR available to specs.

## Background
`rspec-rails` generated `spec/rails_helper.rb` for the original DB-less scaffold, so it contains `config.use_active_record = false` and the AR block commented out. That now contradicts reality.

## You'll know it worked when (deliverable)
`bundle exec rspec` prints `0 examples, 0 failures` and exits 0 — no AR errors.

## Tasks
- [ ] Open `spec/rails_helper.rb`
- [ ] Set `config.use_active_record = true` (or remove the line entirely)
- [ ] Uncomment the ActiveRecord block it references (the `maintain_test_schema!` / `fixtures` lines)
- [ ] Verify: `RAILS_ENV=test bin/rails db:prepare` (creates the test DB schema)
- [ ] Run `bundle exec rspec`

## Acceptance criteria
- [ ] `bundle exec rspec` → `0 examples, 0 failures`, exit code 0
- [ ] No "ActiveRecord is not available" or schema-related errors in output
- [ ] `RAILS_ENV=test bin/rails runner "puts ActiveRecord::Base.connection.adapter_name"` → `sqlite3`

## Files touched
- `spec/rails_helper.rb`

## Tests required
- None (infrastructure ticket — the deliverable IS the test runner working)

## Definition of done
RSpec boots with AR, runs green, test DB exists.

## Out of scope
- Any actual model specs (Ticket 03+)
- Migrations for domain tables (Ticket 03)
