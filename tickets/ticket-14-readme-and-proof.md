# Ticket 14 — README + fresh-clone proof (final ticket)

**Status:** TODO

> Verification note (2026-08-20): README rewritten (overview, design, setup, run, test, full API reference with envelope + status codes, Docker alternative). Fresh-clone proof passed: deleted dev DB → migrate → load_balances → server → real CSV upload → 201, 4× complete, balances exact (4820.50/9974.40/1550.00/1725.60/48679.50). rspec 84 examples 0 failures; rubocop 0 offenses. Also committed Ticket 13 follow-up (rubocop spec/Gemfile autocorrects missed in PR #17).
**Estimate:** ~30 min
**Depends on:** Tickets 01–13

## Goal
A README that lets **anyone — including a grader — run the whole thing from scratch** by following only that document, plus one final end-to-end verification from a clean state. The challenge's "runs and provides feedback" checkbox gets its proof.

## You'll know it worked when (deliverable)
From a **clean database** (delete `storage/development.sqlite3` first), following ONLY the README:
1. `bundle install` → 2. `bin/rails db:migrate` → 3. `bin/rails load_balances` → 4. `bin/rails server` → 5. the README's curl upload of the real challenge CSV returns `201` with all transfers `"complete"` → 6. the README's `GET /accounts` curl shows moved balances.

## Tasks
- [ ] Replace the placeholder `README.md` (currently just `# todo`) with:
  - **Overview**: what this is (Mable take-home), stack (Rails 8.1 API / Ruby 4.0.6 / SQLite / RSpec), one-paragraph design summary
  - **Setup**: rbenv Ruby 4.0.6, `bundle install`, `bin/rails db:migrate`, `bin/rails load_balances`
  - **Run**: `bin/rails server`, base URL note
  - **Test**: `bundle exec rspec` (+ rubocop)
  - **API reference**: all 4 endpoints, the locked envelope `{ status:, data:, error: }`, every status code (`SUCCESS`, `INVALID_FILE_FORMAT`, `FAILED_TO_PARSE_TRANSACTIONS`, `FILE_SIZE_TOO_BIG`; transaction reasons `INSUFFICIENT_BALANCE`, `ACCOUNT_BLOCKED`, `ACCOUNT_NOT_FOUND`), and copy-paste curl examples for upload + the three GETs
  - **Design decisions**: pointer to `POA.md` (state machine, cascade, blocked rules, cents)
- [ ] Follow the README from a clean DB exactly as written — fix the README if any step is wrong or missing (the doc must be sufficient on its own)
- [ ] Final sweep: `bundle exec rspec` + `bin/rubocop` both clean

## Acceptance criteria
- [ ] A stranger with only the README can run the app and see the challenge working end-to-end
- [ ] The real challenge CSV upload returns `201` / `SUCCESS` with 4 `"complete"` transactions against seeded balances
- [ ] `GET /accounts` shows the correct post-transfer balances (1111234522226789: 5000.00 − 500.00 = 4500.00, etc. per the sample data)
- [ ] Full suite green, rubocop clean
- [ ] `tickets/` and `POA.md` are committed alongside (they're part of the deliverable)

## Files touched
- `README.md` (rewrite)

## Tests required
- None new — this ticket's deliverable is the documented proof that everything works

## Definition of done
The project is self-explanatory, runnable from zero, and the take-home is complete.

## Out of scope
- Any code changes beyond README (if code must change to make the README true, that's a bug — fix it, but note it in the ticket)
