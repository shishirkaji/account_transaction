# Ticket 05 — Account validations + factory + specs

**Status:** TODO

> Verification note (2026-08-20): spec-first (red → green). Factory + 6 specs; validations presence/format/uniqueness. rspec 6 examples, 0 failures; SimpleCov 33/33 (100%). Note: test DB needed `RAILS_ENV=test bin/rails db:migrate` (it predated the accounts table).
**Estimate:** ~25 min
**Depends on:** Ticket 03 (accounts table exists), Ticket 04 (factory_bot available)

## Goal
The Account model enforces its core rules: an account number is **required, exactly 16 digits, unique**. First real specs in the project.

## You'll know it worked when (deliverable)
`bundle exec rspec` shows the account specs all green, and this prints `false`:
```
bin/rails runner "puts Account.new(account_number: '123').valid?"
```
plus `bin/rails runner "puts Account.new(account_number: '123').errors[:account_number].inspect"` shows a message.

## Context
- POA: section 4 (Account) — this ticket is validations only; money methods are Ticket 06
- 16-digit rule: `/\A\d{16}\z/` — exactly 16 digits, nothing else

## Tasks
- [ ] Create `spec/factories/accounts.rb`:
  ```ruby
  FactoryBot.define do
    factory :account do
      sequence(:account_number) { |n| format("%016d", n) }
      balance_cents { 0 }
      blocked { false }
      blocked_reason { nil }
    end
  end
  ```
- [ ] In `app/models/account.rb`, add validations:
  - `presence` of `account_number`
  - `format` `/\A\d{16}\z/` on `account_number`
  - `uniqueness` of `account_number`
- [ ] Replace the generated placeholder in `spec/models/account_spec.rb` with real specs covering:
  - a factory account is valid
  - missing `account_number` → invalid, error on `account_number`
  - wrong formats (15 digits, 17 digits, letters) → invalid
  - duplicate `account_number` → invalid
- [ ] Run `bundle exec rspec`

## Acceptance criteria
- [ ] `bundle exec rspec` → all examples pass, 0 failures (Account specs + existing)
- [ ] The runner proof commands above print `false` and a non-empty error array
- [ ] `bin/rails runner "puts Account.create!(account_number: '123').id"` raises `ActiveRecord::RecordInvalid`

## Files touched
- `app/models/account.rb`
- `spec/factories/accounts.rb` (new)
- `spec/models/account_spec.rb`

## Tests required
- The four spec groups listed in Tasks (this ticket's deliverable IS the specs passing)

## Definition of done
Account number rules are enforced and proven by green specs + console proof.

## Out of scope
- `add_balance` / `deduct_balance` / `block` methods and specs (Ticket 06)
- Any other tables or models
