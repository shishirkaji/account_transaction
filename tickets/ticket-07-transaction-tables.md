# Ticket 07 — transaction_files + transactions tables (with bare models)

**Status:** TODO
**Estimate:** ~15 min
**Depends on:** Ticket 03 (migration pattern proven)

## Goal
The two remaining tables exist, with bare models and the **locked status enum**. After this ticket, a file record and its transactions can be created and read back.

## You'll know it worked when (deliverable)
```
bin/rails runner "f = TransactionFile.create!(name: 'demo.csv', uploaded_at: Time.current); t = f.transactions.create!(from_account_number: '1111234522226789', to_account_number: '1212343433335665', amount_cents: 50000); puts [f.valid, t.status, t.transaction_file_id].inspect"
```
prints `[false, "pending", 1]` (or similar ids).

## Context
- POA: section 3 (transaction_files + transactions tables)
- Columns and indexes are locked — copy them exactly

## Tasks
- [ ] Generate: `bin/rails generate model TransactionFile name:string uploaded_at:datetime valid:boolean`
- [ ] In the migration, set `valid` default to `false`
- [ ] Generate: `bin/rails generate model Transaction transaction_file:references from_account_number:string to_account_number:string amount_cents:integer status:string fail_reason:string from_account_old_balance_cents:integer to_account_old_balance_cents:integer`
- [ ] In the transactions migration, add:
  - `status` default `"pending"`
  - indexes: `from_account_number`, `to_account_number`, `status` (non-unique)
- [ ] `bin/rails db:migrate`
- [ ] In `app/models/transaction_file.rb`:
  ```ruby
  class TransactionFile < ApplicationRecord
    has_many :transactions, dependent: :destroy
  end
  ```
- [ ] In `app/models/transaction.rb` add the locked enum:
  ```ruby
  enum :status, { pending: "pending", complete: "complete", failed: "failed" }, default: :pending
  ```

## Acceptance criteria
- [ ] `bin/rails db:migrate` clean; `db/schema.rb` contains both tables with all indexes
- [ ] `bin/rails runner "puts ActiveRecord::Base.connection.tables.inspect"` includes `"transaction_files"` and `"transactions"`
- [ ] Deliverable command prints `[false, "pending", ...]`
- [ ] `bin/rails runner "puts Transaction.statuses.inspect"` → `{"pending" => "pending", "complete" => "complete", "failed" => "failed"}`
- [ ] `bundle exec rspec` still green

## Files touched
- `db/migrate/*_create_transaction_files.rb` (new)
- `db/migrate/*_create_transactions.rb` (new)
- `app/models/transaction_file.rb` (new)
- `app/models/transaction.rb` (new)
- `db/schema.rb` (generated)
- Generated specs (placeholder — real ones come in Tickets 08/09)

## Tests required
- None yet (structure only — proven by console)

## Definition of done
Both tables + models + enum work; a file can own transactions; status defaults to `pending`.

## Out of scope
- CSV parsing (Ticket 08)
- `process!` and status transitions (Ticket 09)
