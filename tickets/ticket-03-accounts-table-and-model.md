# Ticket 03 — Accounts table + bare Account model

**Status:** TODO
**Estimate:** ~20 min
**Depends on:** Ticket 01 (SQLite wired)

## Goal
First real persistence: an `accounts` table, a working `Account` model, and a **visible proof that data survives a round-trip**. No validations, no business methods — those are later tickets.

## You'll know it worked when (deliverable)
```
bin/rails runner "a = Account.create!(account_number: '1111234522226789', balance_cents: 500000); puts a.reload.balance_cents"
```
prints `500000` — data written to SQLite and read back.

## Context
- POA: section 3 (accounts table), section 4 (Account model — this ticket is the skeleton only)
- Table shape: `account_number` (string, 16 digits, **unique index**), `balance_cents` (integer, default 0), `blocked` (boolean, default false), `blocked_reason` (string, nullable), timestamps

## Tasks
- [ ] Generate: `bin/rails generate model Account account_number:string balance_cents:integer blocked:boolean blocked_reason:string`
- [ ] Edit the migration so `balance_cents` defaults to `0` and `blocked` defaults to `false` (add `default:` in the column definitions)
- [ ] Add a **unique index** on `account_number` in the migration (via `add_index :accounts, :account_number, unique: true`)
- [ ] Run `bin/rails db:migrate`
- [ ] Confirm the bare model exists: `app/models/account.rb` contains `class Account < ApplicationRecord; end` (generator creates it)
- [ ] Run the round-trip proof command above

## Acceptance criteria
- [ ] `bin/rails db:migrate` runs clean, `db/schema.rb` now contains the `accounts` table
- [ ] `bin/rails runner "puts ActiveRecord::Base.connection.tables"` includes `"accounts"`
- [ ] Round-trip proof prints `500000`
- [ ] Duplicate account_number is rejected at the DB level: creating a second `1111234522226789` raises (unique index working)
- [ ] `bundle exec rspec` still green (Ticket 02 result preserved)

## Files touched
- `db/migrate/*_create_accounts.rb` (new)
- `app/models/account.rb` (new)
- `db/schema.rb` (generated)
- `spec/models/account_spec.rb` (generated — empty; real specs are a later ticket)

## Tests required
- None yet — this ticket proves persistence manually. Model specs (validations, money methods) are a dedicated later ticket.

## Definition of done
Accounts persist to SQLite, unique on number, round-trip proven.

## Out of scope
- Model validations and business methods (`add_balance`, `deduct_balance`, `block`) — later ticket
- `transaction_files` / `transactions` tables — later tickets
- Any API endpoints
