# Ticket 12 — GET endpoints + as_json shapes

**Status:** TODO
**Estimate:** ~30 min
**Depends on:** Ticket 11 (routes + envelope pattern proven)

## Goal
The three read endpoints — accounts, transactions, transaction_files — all returning the locked envelope with **curated JSON shapes** (`as_json` overrides, locked decision). Money appears as dollar strings at the API boundary; raw cents and timestamps never leak.

## You'll know it worked when (deliverable)
```
bin/rails load_balances
bin/rails runner "puts 'server ready'"
# with the server running:
curl -s http://localhost:3000/accounts
```
returns `200` with `{"status":"SUCCESS","data":[{"account_number":"1111234522226789","balance":"5000.00","blocked":false,"blocked_reason":null}, ...]}` — balance is a 2-decimal dollar string, no `balance_cents`, no `created_at`.

## Context
- POA: section 5 (GETs + envelope), section 10 — **LOCKED: `as_json` overrides, envelope `{ status:, data:, error: }`**
- Format dollars as strings: `50000 → "500.00"` via string math (`sprintf("%d.%02d", cents / 100, cents % 100)`) — never floats

## Tasks — TEST-FIRST (red → green)

**Phase 1: RED — request specs first**
- [ ] Add the routes:
  ```ruby
  get "accounts",           to: "accounts#index"
  get "transactions",       to: "transactions#index"
  get "transaction_files",  to: "transaction_files#index"
  ```
- [ ] Write `spec/requests/accounts_spec.rb` and `spec/requests/transactions_spec.rb` covering:
  - `GET /accounts` → `200`, envelope, each account has `account_number` / `balance` (dollar string) / `blocked` / `blocked_reason` — and **no** `balance_cents`, `id`, or timestamps
  - `GET /transactions` → `200`, envelope, each transaction has `from_account_number`, `to_account_number`, `amount` (dollar string), `status`, `fail_reason`, old-balance fields as dollar strings or `null` — and **no** `amount_cents`
  - `GET /transaction_files` → `200`, envelope, each file has `id`, `name`, `uploaded_at`, `is_valid` — and **no** timestamps
  - empty DB → `200` with `data: []` (not an error)
- [ ] Run the specs → red (`NoMethodError: undefined method 'as_json'` is fine — first prove routing/shape expectations)

**Phase 2: GREEN — implement**
- [ ] Add `as_json` overrides:
  - `Account`: `{ account_number:, balance: <dollar string>, blocked:, blocked_reason: }`
  - `Transaction`: `{ id:, from_account_number:, to_account_number:, amount: <dollar string>, status:, fail_reason:, from_account_old_balance: <dollar string|null>, to_account_old_balance: <dollar string|null> }`
  - `TransactionFile`: `{ id:, name:, uploaded_at:, is_valid: }`
  - Shared private helper `format_cents(cents)` for the dollar strings
- [ ] Create `AccountsController#index`, `TransactionsController#index`, `TransactionFilesController#index` — each renders `{ status: "SUCCESS", data: <collection> }`, `200`
- [ ] Run `bundle exec rspec` → all green

## Acceptance criteria
- [ ] All request specs pass; no raw cents or timestamps in any response
- [ ] Empty DB returns `data: []` with 200
- [ ] Deliverable curl shows the exact shape above
- [ ] `bundle exec rspec` full suite green (all tickets' specs together)

## Files touched
- `config/routes.rb`
- `app/models/account.rb`, `app/models/transaction.rb`, `app/models/transaction_file.rb`
- `app/controllers/accounts_controller.rb` (new)
- `app/controllers/transactions_controller.rb` (new)
- `app/controllers/transaction_files_controller.rb`
- `spec/requests/accounts_spec.rb` (new), `spec/requests/transactions_spec.rb` (new)

## Tests required
- The four request spec groups in Tasks

## Definition of done
All three GETs return curated JSON in the locked envelope; the API surface is complete.

## Out of scope
- Rubric polish pass + README (next batch)
- Coverage gap-closing
