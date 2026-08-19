# Bank Transaction

A minimal banking API for the **Mable Back End Code Challenge**: load account balances, accept a day's transfers as CSV, and never let an account go below $0.

Built with Rails 8.1 (API-only), SQLite, RSpec. Full plan: [`POA.md`](POA.md) · Tickets: [`tickets/`](tickets/) · No-Docker setup: [Run without Docker](docs/local-development.md)

## Quick start (Docker)

```bash
docker compose up --build
```

Serves on <http://localhost:3000> — migrations + seed run automatically on boot. The image pins Ruby 4.0.6, so it works on any machine.

**Custom balances:** mount your own CSV (one `account_number,balance` per line) over the sample in `docker-compose.yml`:

```yaml
volumes:
  - ./storage:/app/storage
  - ./my_balances.csv:/app/data/mable_account_balances.csv
```

Then `docker compose up --build`. Bundled datasets: `data/mable_account_balances_50.csv` (50 accounts) · `data/mable_transactions_100.csv` (100 diverse transfers).

## API

Envelope: `{ "status": ..., "data": ..., "error": ... }`

### POST /transaction_files — upload a day's transfers

Multipart `file` field; rows are `from,to,amount`:

```bash
curl -F "file=@mable_transactions.csv" http://localhost:3000/transaction_files
```

| Status | HTTP | Meaning |
|---|---|---|
| `SUCCESS` | 201 | parsed + processed; `data` has per-transaction statuses |
| `INVALID_FILE_FORMAT` | 422 | missing file / not `.csv` |
| `FILE_SIZE_TOO_BIG` | 413 | file > 1MB |
| `FAILED_TO_PARSE_TRANSACTIONS` | 422 | malformed CSV |

Per-transaction `fail_reason`: `INSUFFICIENT_BALANCE` · `ACCOUNT_BLOCKED` · `ACCOUNT_NOT_FOUND`

### GET /accounts — current balances

```bash
curl http://localhost:3000/accounts
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

Returns 200 when alive.

---

Postman collection: [`postman/`](postman/Mable_Takehome.postman_collection.json)
