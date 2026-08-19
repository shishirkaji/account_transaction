# Ticket 11 — POST /transaction_files (upload → process → envelope)

**Status:** TODO

> Verification note (2026-08-20): spec-first (red → green). 6 request specs + route + controller (size/format checks, parse rescue, ordered processing, envelope). rspec 67 examples, 0 failures. E2E: seeded + curl real challenge CSV → 201 SUCCESS, 4× complete, balances exact (482050 / 997440 / 155000 / 172560 / 4867950). Test-data fix: `1000.00` = 100000¢ drained account to 0 — used `10.00` (1000¢) instead.
**Estimate:** ~45 min (biggest API ticket)
**Depends on:** Tickets 08 (parsing), 09 (process!), 10 (seed, for end-to-end)

## Goal
The upload endpoint: accept a CSV via multipart, create + process it, return the locked envelope. This is the moment the whole system works **over HTTP**.

## You'll know it worked when (deliverable)
```
bin/rails load_balances
bin/rails runner "puts 'server ready'"
# then, with the server running:
curl -s -w "\nHTTP %{http_code}" -F "file=@MableBackEndCodeTest/mable_transactions.csv" http://localhost:3000/transaction_files
```
returns `201` with `{"status":"SUCCESS", ...}` and the transactions array showing `"complete"` statuses; then `bin/rails runner "puts Account.pluck(:account_number, :balance_cents).inspect"` shows the moved balances.

## Context
- POA: section 5 (routes, controllers, envelope `{ status:, data:, error: }`), section 6 (seed), locked status codes: `SUCCESS | INVALID_FILE_FORMAT | FAILED_TO_PARSE_TRANSACTIONS | FILE_SIZE_TOO_BIG`
- Order of checks matters: **missing file → size → format → parse → process**
- The sample `MableBackEndCodeTest/mable_transactions.csv` is the real challenge file — 4 transfers, all valid against the seeded balances

## Tasks — TEST-FIRST (red → green)

**Phase 1: RED — request specs first**
- [ ] Add the route: `post "transaction_files", to: "transaction_files#create"` in `config/routes.rb`
- [ ] Write `spec/requests/transaction_files_spec.rb` covering:
  - valid CSV upload → `201`, envelope `status: "SUCCESS"`, transactions all `"complete"`, accounts' balances moved
  - missing file param → `422`, `INVALID_FILE_FORMAT`
  - oversized file (> 1MB) → `413`, `FILE_SIZE_TOO_BIG` (build it with a huge numeric amount — the size check must fire BEFORE parsing)
  - wrong extension (e.g. `.txt`) → `422`, `INVALID_FILE_FORMAT`
  - malformed CSV (bad row) → `422`, `FAILED_TO_PARSE_TRANSACTIONS`
  - **cascade over HTTP**: two transfers from one account, first insufficient → response shows one `INSUFFICIENT_BALANCE` failed + one `ACCOUNT_BLOCKED` failed (whole system proven)
  - upload helper for specs: `Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "day1.csv")`
- [ ] Run `bundle exec rspec spec/requests/transaction_files_spec.rb` → red (`NoMethodError` / routing errors)

**Phase 2: GREEN — implement**
- [ ] Create `app/controllers/transaction_files_controller.rb` with `create`, in this exact order:
  1. `params[:file]` missing → `422` `{ status: "INVALID_FILE_FORMAT", error: "file is required" }`
  2. `params[:file].size > 1.megabyte` → `413` `{ status: "FILE_SIZE_TOO_BIG", error: "file exceeds 1MB" }`
  3. filename must end in `.csv` → else `422` `{ status: "INVALID_FILE_FORMAT", error: "file must be a CSV" }`
  4. `TransactionFile.create_with_transactions(params[:file].read, name: params[:file].original_filename)` → rescue `TransactionParseError` → `422` `{ status: "FAILED_TO_PARSE_TRANSACTIONS", error: e.message }`
  5. `file.transactions.each(&:process!)` (order = file order)
  6. render `201` `{ status: "SUCCESS", data: { transaction_file: file.as_json, transactions: file.transactions.map(&:as_json) } }`
- [ ] Run `bundle exec rspec` → all green
- [ ] Only after green: run the deliverable (seed → start server → curl → check balances)

## Acceptance criteria
- [ ] All request specs pass; SimpleCov controller ≥ 90%
- [ ] Every failure mode returns the envelope with the locked status code
- [ ] Deliverable: real challenge CSV → 201, all 4 transfers complete, balances moved exactly per the sample data

## Files touched
- `config/routes.rb`
- `app/controllers/transaction_files_controller.rb` (new)
- `spec/requests/transaction_files_spec.rb` (new)

## Tests required
- The six request spec groups in Tasks

## Definition of done
Upload a CSV over HTTP → it's parsed, processed in order, and answered with the locked envelope; every failure mode has a proven code.

## Out of scope
- The three GET endpoints (Ticket 12)
- `as_json` shapes (Ticket 12)
