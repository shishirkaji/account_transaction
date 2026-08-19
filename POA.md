# POA — Mable Backend Take-Home: `solution_transaction`

Status: PLANNING (no code written yet beyond bare scaffold)
Next step: convert into ticket-level specs for a junior engineer

---

## 0. The challenge (one paragraph)

A company provides two CSVs: one with starting account balances for a single
company, one with a day's transfers. Accounts are 16-digit numbers. A transfer
must never push the from-account below $0. Build a system that loads balances,
accepts a day's transfers, applies the rules, and exposes the resulting state.

## 1. Locked decisions (do not revisit without reason)

| Area | Decision |
|---|---|
| Stack | Rails 8.1.3.1 API-only, Ruby 4.0.6 (rbenv), RSpec 8 |
| Database | **SQLite** (file-based, no Docker, no server) |
| Money | Store **cents as integers** (`balance_cents`, `amount_cents`). Never floats. Parse 2-decimal CSV once, format to dollars only at the API boundary |
| Account numbers | **Strings**, always (16 digits, opaque identifiers, no arithmetic) |
| Naming | Ruby snake_case everywhere; transfer value is `amount`, never `balance` |
| Transaction states | `pending` (initial) → `complete` \| `failed` (both terminal). **Immutable once it leaves `pending`** |
| Blocked accounts | `blocked = cannot send, CAN still receive`. Only the from-account is ever blocked. Never block the to-account |
| Cascade rule | Insufficient funds on a transfer → that transfer fails → from-account gets blocked → all later transfers from that account in the same file fail with `ACCOUNT_BLOCKED` (never `pending`) |
| No retries | Failed is terminal. Any future retry must create new transactions |
| Self-transfers | **Allowed** (from == to): deduct then add, net zero, requires sufficient funds, never blocks |
| Balances loading | **Seed task** (`bin/rails` rake task reading the balances CSV), never a boot initializer |
| Upload size limit | 1MB (`FILE_SIZE_TOO_BIG` beyond it) |
| Processing | Synchronous, in file row order. (Queue/worker from earlier brainstorm is explicitly out of scope — models must not change if it's added later) |

## 2. One-time setup (SQLite + ActiveRecord)

1. Add `gem "sqlite3"` to Gemfile → `bundle install`
2. Re-enable AR: uncomment `require "active_record/railtie"` in `config/application.rb`
3. Add `config/database.yml` (development + test; SQLite file DBs — no server, no `db:create` needed)
4. Remove `config.use_active_record = false` block from `spec/rails_helper.rb` (rspec-rails generated it for the DB-less scaffold)
5. Verify: `bin/rails runner "puts ActiveRecord::Base.connection.adapter_name"` → `sqlite3`
6. Confirm `bundle exec rspec` still green (0 examples)

## 3. Data model (3 tables via migrations)

### `accounts`
| Column | Type | Notes |
|---|---|---|
| `account_number` | string | 16 digits, **unique index**, indexed for lookup |
| `balance_cents` | integer | default 0 |
| `blocked` | boolean | default false |
| `blocked_reason` | string | nullable |

Timestamps on all tables. Validation: presence + format `/\A\d{16}\z/` + uniqueness.

### `transaction_files`
| Column | Type | Notes |
|---|---|---|
| `name` | string | original file name |
| `uploaded_at` | datetime | set at creation |
| `is_valid` | boolean | file parsed OK (vs. rejected at file level) |

`has_many :transactions`.

### `transactions`
| Column | Type | Notes |
|---|---|---|
| `transaction_file_id` | FK | index; belongs_to :transaction_file |
| `from_account_number` | string | **denormalized string, not FK** — keeps history intact + audit-friendly |
| `to_account_number` | string | same |
| `amount_cents` | integer | |
| `status` | string | `pending` \| `complete` \| `failed` (enum) |
| `fail_reason` | string | nullable; codes below |
| `from_account_old_balance_cents` | integer | nullable; captured **before** mutation |
| `to_account_old_balance_cents` | integer | nullable; captured **before** mutation |

Indexes: `transaction_file_id`, `status`, `from_account_number`, `to_account_number` (non-unique — account numbers appear in many rows; used by every `process!` lookup).

### Fail-reason codes (transaction level)
`INSUFFICIENT_BALANCE`, `ACCOUNT_BLOCKED`, `ACCOUNT_NOT_FOUND`.
(Parse-level failures never create transactions — see API codes.)

### API-level status codes (file upload response)
`SUCCESS`, `INVALID_FILE_FORMAT`, `FAILED_TO_PARSE_TRANSACTIONS`, `FILE_SIZE_TOO_BIG`.
File-level checks happen **before** parsing; parse failures happen mid-parse;
`SUCCESS` returns the full transaction array with per-transaction statuses.

## 4. Domain logic (models)

### Account
- Class: `find_by_account_number(number)` (AR scope — the "load balances on start" store)
- Instance: `add_balance(amount_cents)` → returns new balance
- Instance: `deduct_balance(amount_cents)` → returns new balance, or **raises** `InsufficientBalanceError` if it would go below $0
  - **Pure math only** — does NOT check `blocked`; policy lives in Transaction#process!
  - Deducting exactly to $0 is allowed (spec: "below $0")
- Instance: `block(reason)` → sets `blocked` + `blocked_reason`
- Custom error class: `app/errors/insufficient_balance_error.rb` (plain `StandardError` subclass)

### TransactionFile
- Class entry point (called by controller): `create_with_transactions(csv_buffer, name:)`
  - Validates format/columns/amounts → raises typed errors mapped to API codes
  - Creates the file record + one `pending` Transaction per valid row, **in file order**
  - Returns `[file, transactions]`
- `is_valid` reflects whether parsing succeeded

### Transaction
- Enum: `pending` / `complete` / `failed`
- `process!` — the core method, in order:
  1. Guard: raise unless `pending` ("Transaction only gets processed once")
  2. Resolve from- and to-Accounts by number; missing → `fail(ACCOUNT_NOT_FOUND)`
  3. Capture `from_account_old_balance_cents` / `to_account_old_balance_cents`
  4. From-account `blocked?` → `fail(ACCOUNT_BLOCKED)` (this is what makes the cascade work)
  5. `from_account.deduct_balance(amount_cents)` → rescue `InsufficientBalanceError` → `fail(INSUFFICIENT_BALANCE)` **and** `from_account.block("insufficient balance")`
  6. `to_account.add_balance(amount_cents)` (to-account being blocked does NOT stop this — locked decision)
  7. `complete`
- `fail(reason)` / `complete` — private-ish setters that transition + persist; enforce immutability
- Old-balance audit fields: written at step 3, never after

## 5. API layer

### Routes
```
POST /transaction_files          # multipart CSV upload
GET  /accounts                   # all current balances
GET  /transactions               # all transactions
GET  /transaction_files          # all file records
GET  /up                         # health (exists)
```

### Controllers (thin — application logic only)
- `TransactionFilesController#create`
  1. File param present? missing → 422
  2. Size check (limit TBD, suggest 1MB) → `FILE_SIZE_TOO_BIG`
  3. Format check (extension/content-type CSV) → `INVALID_FILE_FORMAT`
  4. `TransactionFile.create_with_transactions(...)` → rescue parse errors → `FAILED_TO_PARSE_TRANSACTIONS`
  5. Process all transactions in order (loop `transaction.process!`)
  6. Render envelope: `{ status: "SUCCESS", transaction_file: {...}, transactions: [...] }` → 201
- `AccountsController#index`, `TransactionsController#index`, `TransactionFilesController#index` → simple `render json:` of collections (use model `as_json` overrides; no serializer gem unless it earns its place)

### Response envelope (decide + document)
Single consistent shape, e.g. `{ status:, data:, error: }` — success and every
failure mode use the same envelope so the API is predictable.

## 6. "Loads balances on start"

**LOCKED: seed task** — `lib/tasks/load_balances.rake` (or `db:seed`) reading `mable_account_balances.csv`, invoked explicitly (`bin/rails load_balances`).

- Never a boot initializer (would pollute test runs and silently reset demo state)
- Idempotency: **clear-and-reload** — wipe `accounts` then insert from CSV, so re-running is always deterministic
- Note: `db:migrate` on a fresh clone does NOT seed; the seed is a separate explicit step (document in README)

## 7. Tests (RSpec) — mapped to rubric

### Setup
- Factories: factory_bot (recommended) vs. plain AR `create` in specs — pick one
- Transactional tests (AR default) — no database_cleaner needed
- Target: meaningful coverage of every branch below (rubric: "good coverage")

### Account spec
- `deduct_balance`: success returns new balance; exact-to-$0 allowed; below-$0 raises `InsufficientBalanceError`; balance unchanged after raise
- `add_balance`: returns new balance
- `block`: sets `blocked` + reason
- Validations: 16-digit format, uniqueness, presence

### TransactionFile spec
- Valid CSV → file record + transactions in file order, all `pending`
- Malformed: wrong column count, non-numeric amount, negative/zero amount, empty file, blank lines → typed parse errors
- Size limit enforcement (if enforced at model level too)

### Transaction spec (the core business rules)
- Happy path: balances move, old balances captured, status `complete`
- Only-once guard: processing a non-pending transaction raises
- From-account blocked → `failed`/`ACCOUNT_BLOCKED`
- Insufficient funds → `failed`/`INSUFFICIENT_BALANCE` + from-account now blocked
- **Cascade**: second transfer from the same account in one file → `failed`/`ACCOUNT_BLOCKED`
- To-account blocked → still completes, funds received (locked edge case)
- Unknown account number → `failed`/`ACCOUNT_NOT_FOUND`
- Immutability: `complete`/`failed` cannot be re-processed or re-opened
- Order preservation: file row order = processing order

### Controller/request specs
- POST: success envelope 201; each failure code with its status; missing file param
- GETs: each returns the expected collection
- Business logic **stubbed at controller level** (only application logic tested here — locked decision)

## 8. Edge cases (locked; all have tests)

1. Two transfers from account A, first insufficient → first fails, A blocked, second fails `ACCOUNT_BLOCKED`
2. Blocked to-account still receives funds
3. Only from-accounts ever get blocked
4. Deduct to exactly $0 → allowed
5. Unknown account in CSV → `ACCOUNT_NOT_FOUND` on that transaction
6. **Self-transfer (from == to)** — ALLOWED: deduct then add (net zero), requires sufficient funds, never blocks the account
7. Immutable once past `pending`
8. Zero/negative amounts → parse-level rejection
9. Order = file row order, always
10. 16-digit numbers: strings end-to-end; no precision loss

## 9. Rubric self-check

- Domain models ✓ (Account, TransactionFile, Transaction)
- Native data structures readably ✓
- RSpec + good, orthogonal coverage ✓ (section 7)
- OO encapsulation ✓ (money ops on Account, status machine on Transaction)
- Separation of concerns ✓ (thin controllers, rules in models)
- Short/readable methods ✓ (enforce during review; no method > ~8 lines)
- Runs and provides feedback ✓ (server + 4 endpoints)
- Tests explain functionality ✓ (describe/it naming tells the story)

## 10. Open decisions to lock before ticket-level specs

1. ~~Self-transfer policy~~ — **LOCKED: allow**
2. ~~Upload size limit~~ — **LOCKED: 1MB**
3. ~~Response envelope~~ — **LOCKED: `{ status:, data:, error: }`**
4. ~~Balances loading~~ — **LOCKED: seed task, clear-and-reload**
5. ~~Money~~ — **LOCKED: cents as integers** (`*_cents`, single parse/format helpers)
6. ~~`from`/`to` as denormalized strings vs FKs~~ — **LOCKED: denormalized account-number strings** (audit record, supports `ACCOUNT_NOT_FOUND`, no joins on read)
7. ~~factory_bot vs plain fixtures~~ — **LOCKED: factory_bot**
8. ~~Enum vs plain string for `status`~~ — **LOCKED: Rails enum**
9. ~~Where `InsufficientBalanceError` lives~~ — **LOCKED: `app/errors/`**
10. ~~JSON: `as_json` overrides vs serializer gem~~ — **LOCKED: `as_json` overrides on the 3 models**

## 11. Execution order (feeds the future ticket list)

1. **T1** SQLite + AR setup (section 2) + verify boot/tests
2. **T2** Migrations: accounts, transaction_files, transactions (section 3)
3. **T3** Account model + specs
4. **T4** Transaction model: status machine, fail/complete, immutability + specs
5. **T5** TransactionFile parsing + typed errors + specs
6. **T6** Transaction#process! + cascade + specs (the heart)
7. **T7** Routes + controllers + request specs
8. **T8** Balances loading (seed task) + demo data
9. **T9** Rubric pass: naming, method length, coverage gaps, README with run instructions

