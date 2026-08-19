# Ticket 09 — Transaction#process! (the heart)

**Status:** TODO
**Estimate:** ~45 min (biggest ticket — it carries the business rules)
**Depends on:** Ticket 06 (Account money methods), Ticket 08 (parsing)

## Goal
A `pending` transaction gets executed: accounts resolved, old balances captured, funds moved, status set. All locked business rules live here — including the cascade. After this ticket the core of the challenge works end-to-end.

## You'll know it worked when (deliverable)
```
bin/rails runner "
a = Account.create!(account_number: '1111234522226789', balance_cents: 500000)
b = Account.create!(account_number: '1212343433335665', balance_cents: 120000)
f = TransactionFile.create!(name: 'x.csv', uploaded_at: Time.current, valid: true)
t = f.transactions.create!(from_account_number: a.account_number, to_account_number: b.account_number, amount_cents: 50000)
t.process!
puts [a.reload.balance_cents, b.reload.balance_cents, t.reload.status, t.from_account_old_balance_cents, t.to_account_old_balance_cents].inspect
"
```
prints `[450000, 170000, "complete", 500000, 120000]`.

## Context
- POA: section 4 (Transaction#process!), section 8 edge cases — ALL locked, follow exactly
- `deduct_balance` raises `InsufficientBalanceError` (Ticket 06); `deduct_balance` does NOT check `blocked` — `process!` does
- Self-transfer allowed (net zero); to-account blocked still receives; only from-account ever blocked; immutability once past `pending`

## Tasks — TEST-FIRST (red → green)

**Phase 1: RED — write the specs, prove they fail**
- [ ] Write the 8 spec groups in `spec/models/transaction_spec.rb` (use factories; build accounts + transactions per case):
  - happy path: balances move, old balances recorded, status `complete`
  - only-once guard: processing a `complete` transaction raises
  - from-account blocked → `failed`/`ACCOUNT_BLOCKED`, balances untouched
  - insufficient funds → `failed`/`INSUFFICIENT_BALANCE` **and** from-account now blocked
  - **cascade**: second transaction from the now-blocked account → `failed`/`ACCOUNT_BLOCKED`
  - to-account blocked → still `complete`, funds received
  - unknown account → `failed`/`ACCOUNT_NOT_FOUND`
  - self-transfer (from == to) → allowed, net zero, `complete`
- [ ] Run `bundle exec rspec spec/models/transaction_spec.rb` → confirm failures (NoMethodError: undefined method `process!`) — **this red is the proof the specs describe real behavior**

**Phase 2: GREEN — implement until the specs pass**
- [ ] In `app/models/transaction.rb`, implement in this exact order:
  1. **Guard**: raise `"Transaction only gets processed once"` unless `pending?`
  2. Resolve `from_account` / `to_account` by `find_by(account_number:)`
  3. **Capture old balances** (`from_account_old_balance_cents`, `to_account_old_balance_cents`) from the resolved accounts (nil if account missing)
  4. Missing account(s) → `fail("ACCOUNT_NOT_FOUND")` and stop
  5. `from_account.blocked?` → `fail("ACCOUNT_BLOCKED")` and stop
  6. `from_account.deduct_balance(amount_cents)` → rescue `InsufficientBalanceError` → `from_account.block("insufficient balance")` → `fail("INSUFFICIENT_BALANCE")` and stop
  7. `to_account.add_balance(amount_cents)` (blocked to-account does NOT stop this)
  8. `complete`
- [ ] Implement the two transition helpers:
  - `fail(reason)` → sets `status = :failed` + `fail_reason = reason`, saves
  - `complete` → sets `status = :complete`, saves
- [ ] Run `bundle exec rspec` → all green + check SimpleCov
- [ ] Only after green: run the deliverable command below as an end-to-end sanity check

## Acceptance criteria
- [ ] All specs pass, 0 failures; SimpleCov Transaction ≥ 90%
- [ ] Deliverable command prints `[450000, 170000, "complete", 500000, 120000]`
- [ ] A processed transaction's status never changes again (immutability covered by only-once spec)

## Files touched
- `app/models/transaction.rb`
- `spec/models/transaction_spec.rb`

## Tests required
- The eight spec groups in Tasks (this ticket's deliverable IS the rules proven)

## Definition of done
Every locked business rule — happy path, guard, blocked, insufficient + cascade, to-blocked, unknown account, self-transfer — is implemented and proven by green specs.

## Out of scope
- HTTP endpoints / controllers (next batch)
- Processing a whole file in a loop (next batch — `file.transactions.each(&:process!)`)
- Seed task for balances (next batch)
