# Ticket 13 — Rubric polish (rubocop, readability, coverage)

**Status:** TODO
**Estimate:** ~30 min
**Depends on:** Tickets 01–12 (all functionality exists and is green)

## Goal
Make the codebase rubric-clean without changing any behavior: **0 rubocop offenses**, short readable methods, coverage gaps closed. The rubric's "short methods / readable methods / separation of concerns" checkboxes get visibly ticked.

## You'll know it worked when (deliverable)
```
bin/rubocop
```
prints `0 offenses detected`, and:
```
bundle exec rspec
```
is fully green with SimpleCov showing **≥ 90%** on models and controllers.

## Context
- POA: section 9 (rubric self-check) — this ticket executes it
- Rubocop is already installed (rubocop-rails-omakase in the Gemfile, `bin/rubocop` available)

## Tasks
- [ ] Run `bin/rubocop` and read every offense — fix them one by one
- [ ] Review every method: if any exceeds ~8 lines, extract private helpers (e.g. `TransactionFilesController#create` may warrant helpers for the render paths)
- [ ] Check SimpleCov output: models and controllers at ≥ 90%. Close small gaps with targeted specs only — do NOT add tests for tests' sake
- [ ] Re-run `bin/rubocop` and `bundle exec rspec` until both are clean

## Rules (important)
- **Never change a locked behavior to satisfy a cop** (POA is the source of truth: snake_case, cents, enum values, cascade, envelope). If a cop genuinely conflicts with a locked decision, disable that cop inline with a one-line comment explaining why — that's exactly the kind of "needed" comment allowed
- No new dependencies, no new files beyond what's needed for fixes
- All existing specs must pass **unchanged** — if you're tempted to edit a spec to make it pass, you've changed behavior; stop and ask

## Acceptance criteria
- [ ] `bin/rubocop` → `0 offenses detected`
- [ ] `bundle exec rspec` → all green (every ticket's specs together)
- [ ] SimpleCov: models ≥ 90%, controllers ≥ 90%
- [ ] No locked decision changed (verify against POA)
- [ ] No method is a wall of code — each reads in one breath

## Files touched
- Whatever rubocop flags (expect `app/`, `spec/`)
- Possibly small spec additions for coverage gaps

## Tests required
- Only gap-closing specs (existing specs must stay untouched)

## Definition of done
A grader running rubocop + rspec sees a clean, readable, fully-covered codebase.

## Out of scope
- README and fresh-clone verification (Ticket 14)
- Any new features or behavior changes
