# Ticket 10 — Seed task: load account balances

**Status:** TODO

> Verification note (2026-08-20): data CSV copied; `load_balances` task (clear-and-reload). Run 1 → `[5, 500000]`; run 2 → still 5 (no dupes). All 5 balances match CSV (5000.00→500000 etc.). rspec 61 examples, 0 failures.
**Estimate:** ~15 min
**Depends on:** Ticket 03 (accounts table)

## Goal
A one-command seed: `bin/rails load_balances` reads the balances CSV and fills the `accounts` table. **Clear-and-reload** (locked): re-running always produces the same 5 accounts — never duplicates.

## You'll know it worked when (deliverable)
```
bin/rails load_balances
bin/rails runner "puts [Account.count, Account.find_by(account_number: '1111234522226789').balance_cents].inspect"
```
prints `[5, 500000]` — and running `load_balances` a second time still prints `[5, 500000]` (idempotent, no dupes).

## Context
- POA: section 6 — **LOCKED: seed task, clear-and-reload, never a boot initializer**
- The sample CSV lives at `MableBackEndCodeTest/mable_account_balances.csv` (inside the project); we copy it to `data/` so the seed is self-contained
- Amounts are dollars with 2 decimals; store cents via **string math** (same helper pattern as Ticket 08 — no floats)

## Tasks
- [ ] Create `data/` directory and copy `MableBackEndCodeTest/mable_account_balances.csv` → `data/mable_account_balances.csv`
- [ ] Create `lib/tasks/load_balances.rake` with a `load_balances` task:
  1. `Account.delete_all` (clear)
  2. Read `data/mable_account_balances.csv` (rows: `account_number,balance`)
  3. For each row: create account with `balance_cents` parsed from the dollars string, `blocked: false`
- [ ] Run `bin/rails load_balances` twice and run the deliverable command

## Acceptance criteria
- [ ] First run: `Account.count == 5`, balances match the CSV (e.g. `1111234522226789` → `500000`)
- [ ] Second run: still exactly 5 accounts (clear-and-reload works, no `RecordNotUnique` errors)
- [ ] `bin/rails runner "puts Account.pluck(:account_number).size"` → `5`
- [ ] `bundle exec rspec` still green

## Files touched
- `data/mable_account_balances.csv` (new)
- `lib/tasks/load_balances.rake` (new)

## Tests required
- None (infrastructure/data task — proven by the deliverable command, same as Tickets 01–03)

## Definition of done
Balances load on command, deterministically, with no duplicates on re-run.

## Out of scope
- Any automatic loading at boot (explicitly forbidden — locked decision)
- HTTP endpoints
