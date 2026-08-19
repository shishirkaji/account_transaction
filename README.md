# Solution Transaction

A minimal banking API for the **Mable Back End Code Challenge**: load account
balances from a CSV, accept a day's transfers as a CSV, and enforce that no
account ever goes below $0.

Built with **Rails 8.1 (API-only)**, **Ruby 4.0.6**, **SQLite**, and **RSpec**.

## Design summary

- **Account** — a 16-digit account number, a balance (stored as cents), and an
  optional blocked flag. `add_balance`, `deduct_balance` (raises
  `InsufficientBalanceError` below $0), `block`.
- **TransactionFile** — a record of an uploaded CSV. Parsing creates one
  `pending` Transaction per row, in file order; a file that fails to parse is
  kept with `is_valid: false` and zero transactions.
- **Transaction** — an immutable, append-only ledger row: `pending` →
  `complete`/`failed`, and once it leaves `pending` it can never be changed or
  deleted. `process!` executes the transfer atomically.
- **Rules** — blocked accounts can receive but not send; an insufficient
  balance fails the transfer and blocks the from-account, so later transfers
  from it in the same file fail with `ACCOUNT_BLOCKED`. Self-transfers are
  allowed (net zero).
- Money is always stored and computed in **cents** (integers); dollars are
  formatted only at the API boundary.

Full plan and decisions: [`POA.md`](POA.md). Ticket breakdown:
[`tickets/`](tickets/).

## Quick start — Docker (recommended)

No Ruby install needed. With [Docker](https://www.docker.com/) installed:

```bash
docker compose up --build
```

The container runs migrations + seeds on boot and serves on
<http://localhost:3000> — ready in one command, regardless of your Ruby
version. The SQLite file persists on your machine via the `./storage` volume.

To stop: `Ctrl+C`, or `docker compose down`.

> The Docker image pins Ruby 4.0.6, so the app behaves identically on any
> machine. Local development below remains an option if you prefer it.

## Requirements (local development only)

Skip this section if you ran the Docker quick start above.

- Ruby 4.0.6 (via rbenv or your preferred manager)
- Bundler
- SQLite 3 (macOS ships it)

## Alternative: run locally without Docker

Preferred when you already have Ruby 4.0.6 set up.

### Setup

```bash
bundle install
bin/rails db:migrate
bin/rails load_balances    # loads the 5 sample accounts from data/mable_account_balances.csv
```

`db:migrate` creates `storage/development.sqlite3`; `load_balances` clears and
reloads the accounts from the sample CSV (safe to re-run anytime).

### Run

```bash
bin/rails server
```

The API listens on <http://localhost:3000>.

### Test

```bash
bundle exec rspec
bin/rubocop
```

## API

All responses use the envelope `{ "status": ..., "data": ..., "error": ... }`.

### POST /transaction_files — upload a day's transfers

Send a CSV via multipart (`file` field). Rows are `from,to,amount`, e.g.:

```
1111234522226789,1212343433335665,500.00
```

```bash
curl -F "file=@mable_transactions.csv" http://localhost:3000/transaction_files
```

Responses:

| Status | HTTP | Meaning |
|---|---|---|
| `SUCCESS` | 201 | file parsed and processed; `data` holds the file + transactions with per-transaction statuses |
| `INVALID_FILE_FORMAT` | 422 | missing file, or filename does not end in `.csv` |
| `FILE_SIZE_TOO_BIG` | 413 | file larger than 1MB |
| `FAILED_TO_PARSE_TRANSACTIONS` | 422 | malformed CSV (wrong columns, bad amount) |

Per-transaction `fail_reason` codes: `INSUFFICIENT_BALANCE`,
`ACCOUNT_BLOCKED`, `ACCOUNT_NOT_FOUND`.

### GET /accounts — current balances

```bash
curl http://localhost:3000/accounts
```

```json
{ "status": "SUCCESS", "data": [{ "account_number": "1111234522226789", "balance": "5000.00", "blocked": false, "blocked_reason": null }] }
```

### GET /transactions — all transactions

```bash
curl http://localhost:3000/transactions
```

### GET /transaction_files — all uploaded files

```bash
curl http://localhost:3000/transaction_files
```

### GET /up — health check

Returns 200 when the app is alive.
