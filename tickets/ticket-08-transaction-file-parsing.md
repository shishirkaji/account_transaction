# Ticket 08 — TransactionFile parses CSV into pending transactions

**Status:** TODO
**Estimate:** ~30 min
**Depends on:** Ticket 07 (tables exist)

## Goal
`TransactionFile.create_with_transactions(csv_string, name:)` — the file's entry point: creates the file record, parses every row into a `pending` Transaction **in file order**, marks the file as parsed. Bad CSV → file marked unparsed, no transactions, error raised.

## You'll know it worked when (deliverable)
```
bin/rails runner "
csv = \"1111234522226789,1212343433335665,500.00\n3212343433335755,2222123433331212,1000.00\"
file = TransactionFile.create_with_transactions(csv, name: 'day1.csv')
puts [file.is_valid, file.transactions.map { |t| [t.from_account_number, t.to_account_number, t.amount_cents, t.status] }].inspect
"
```
prints `[true, [["1111234522226789", "1212343433335665", 50000, "pending"], ["3212343433335755", "2222123433331212", 100000, "pending"]]]` — note order preserved and `500.00 → 50000` cents.

## Context
- POA: section 4 (TransactionFile), locked decisions: cents via string parsing (never floats); no header row; order = file order
- **Ruby 4.x needs `csv` declared explicitly** (bundled gem) — first task
- Error class: `app/errors/transaction_parse_error.rb` (Zeitwerk autoloads it)

## Tasks — TEST-FIRST (red → green)

**Phase 1: RED — write the specs, prove they fail**
- [ ] Write the 4 spec groups in `spec/models/transaction_file_spec.rb`:
  - valid CSV → file `is_valid: true`, N transactions in order, all `pending`
  - wrong column count → raises, file exists with `is_valid: false`, **zero transactions created**
  - non-numeric amount → raises
  - negative/zero amount → raises
- [ ] Run `bundle exec rspec spec/models/transaction_file_spec.rb` → confirm failures (`NoMethodError: undefined method 'create_with_transactions'`) — **this red is the proof the specs describe real behavior**

**Phase 2: GREEN — implement until the specs pass**
- [ ] Add `gem "csv"` to the Gemfile → `bundle install` (Ruby 4.x needs it declared explicitly)
- [ ] Create `app/errors/transaction_parse_error.rb`:
  ```ruby
  class TransactionParseError < StandardError; end
  ```
- [ ] In `app/models/transaction_file.rb`, implement:
  - `self.create_with_transactions(csv_string, name:)`:
    1. create file record (`is_valid: false`, `uploaded_at: Time.current`)
    2. parse all rows into an array (raises on any bad row — **no transactions created yet**)
    3. on success: bulk-create the pending transactions in order, set `is_valid = true`
    4. on `TransactionParseError`: leave the file record as `is_valid: false`, re-raise
  - a private `parse_amount_to_cents(amount_string)` helper: `"500.00" → 50000`, `"500" → 50000` — **string math only, never `to_f`**
- [ ] Row rules (raise `TransactionParseError` with a clear message on violation):
  - exactly 3 comma-separated columns (`from`, `to`, `amount`)
  - skip blank lines
  - amount matches `\A\d+(\.\d{1,2})?\z` and is > 0
- [ ] Run `bundle exec rspec` → all green; check SimpleCov TransactionFile ≥ 90%
- [ ] Only after green: run the deliverable command below as an end-to-end sanity check

## Acceptance criteria
- [ ] All specs pass, 0 failures
- [ ] Deliverable command prints the expected arrays (order preserved, cents correct)
- [ ] On parse failure: file record persisted with `is_valid: false`, `file.transactions.count == 0`
- [ ] SimpleCov TransactionFile coverage ≥ 90%

## Files touched
- `Gemfile`, `Gemfile.lock`
- `app/errors/transaction_parse_error.rb` (new)
- `app/models/transaction_file.rb`
- `spec/models/transaction_file_spec.rb`

## Tests required
- The four spec groups in Tasks

## Definition of done
A CSV becomes a file record + ordered pending transactions, or a clearly-failed file record with an error. No floats anywhere.

## Out of scope
- Processing transactions (Ticket 09)
- Account resolution / validation of account numbers (Ticket 09)
- HTTP endpoint (later ticket)
