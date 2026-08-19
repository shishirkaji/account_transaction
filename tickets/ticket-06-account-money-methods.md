# Ticket 06 — Account money methods + specs

**Status:** TODO
**Estimate:** ~30 min
**Depends on:** Ticket 05 (validations done)

## Goal
Account gets its three business methods — `add_balance`, `deduct_balance`, `block` — with full specs. Money is **cents as integers** (locked decision), and deducting below $0 raises `InsufficientBalanceError` (locked: `app/errors/`).

## You'll know it worked when (deliverable)
`bundle exec rspec` green, and these console proofs behave as shown:
```
bin/rails runner "a = Account.create!(account_number: '1111234522226789', balance_cents: 500000); puts a.add_balance(50000)"
# → 550000

bin/rails runner "a = Account.create!(account_number: '1111234522226789', balance_cents: 500000); begin; a.deduct_balance(999999999); rescue InsufficientBalanceError => e; puts 'raised'; end"
# → raised

bin/rails runner "a = Account.create!(account_number: '1111234522226789'); a.block('fraud'); puts [a.blocked?, a.blocked_reason].inspect"
# → [true, "fraud"]
```

## Context
- POA: section 4 (Account), locked decisions: cents integers; `deduct_balance` is **pure math** — it does NOT check `blocked` (that policy lives in Transaction#process!); deducting exactly to $0 is allowed
- Error class lives in `app/errors/` (Zeitwerk autoloads it — no require needed)

## Tasks — TEST-FIRST (red → green)

**Phase 1: RED — write the specs, prove they fail**
- [ ] Write the 5 spec groups in `spec/models/account_spec.rb` (use the factory from Ticket 05):
  - `add_balance`: increases balance, returns new balance
  - `deduct_balance`: decreases balance, returns new balance
  - `deduct_balance` exactly to $0 → allowed (no raise)
  - `deduct_balance` below $0 → raises `InsufficientBalanceError`, and **balance is unchanged** after the raise
  - `block`: sets `blocked` true + `blocked_reason`, returns nil
- [ ] Run `bundle exec rspec spec/models/account_spec.rb` → confirm failures (`NameError: uninitialized constant InsufficientBalanceError` + `NoMethodError` on the missing methods) — **this red is the proof the specs describe real behavior**

**Phase 2: GREEN — implement until the specs pass**
- [ ] Create `app/errors/insufficient_balance_error.rb`:
  ```ruby
  class InsufficientBalanceError < StandardError; end
  ```
- [ ] In `app/models/account.rb` add:
  - `add_balance(amount_cents)` → adds to `balance_cents`, saves, returns the new balance
  - `deduct_balance(amount_cents)` → if `amount_cents > balance_cents` raise `InsufficientBalanceError`; otherwise subtract, save, return the new balance
  - `block(reason)` → sets `blocked = true` and `blocked_reason = reason`, saves, returns nil
- [ ] Run `bundle exec rspec` → all green; check the SimpleCov % for the Account model
- [ ] Only after green: run the console proofs below as a sanity check

## Acceptance criteria
- [ ] All specs pass, 0 failures
- [ ] Console proofs above produce the shown outputs
- [ ] SimpleCov shows Account model coverage ≥ 90%
- [ ] `deduct_balance` does not consult `blocked` (deliberate — policy lives in Transaction)

## Files touched
- `app/errors/insufficient_balance_error.rb` (new)
- `app/models/account.rb`
- `spec/models/account_spec.rb`

## Tests required
- The five spec groups in Tasks

## Definition of done
Account can add, deduct (with the insufficient-funds guard), and block — all proven by specs and console.

## Out of scope
- Transaction / TransactionFile models (next tickets)
- `Transaction#process!` (which will call these methods)
- Any API endpoints
