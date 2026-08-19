# Bank Transaction

A minimal banking API for the **Mable Back End Code Challenge**: load account balances, accept a day's transfers as CSV, and never let an account go below $0.

Built with Rails 8.1 (API-only), SQLite, RSpec. Full plan: [`POA.md`](POA.md) · Tickets: [`tickets/`](tickets/) · No-Docker setup: [Run without Docker](docs/local-development.md)

## Quick start (Docker)

```bash
docker compose up --build
```

Serves on <http://localhost:3000> — migrations + seed run automatically on boot. The image pins Ruby 4.0.6, so it works on any machine.

**Custom balances:** mount your own initial account balance csv file by changing the mounted volume in `docker-compose.yml`. Change this `./data/mable_account_balances_50.csv` to point your file.

## API

### POST /transaction_files — upload a day's transfers
Use Bundled datasets provided or use your own: `data/mable_account_balances_50.csv` (50 accounts) · `data/mable_transactions_100.csv` (100 diverse transfers).
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

Example response (truncated to one transaction):

```json
{
  "status": "SUCCESS",
  "data": {
    "transaction_file": { "id": 1, "name": "mable_transactions.csv", "is_valid": true },
    "transactions": [
      {
        "from_account_number": "1111234522226789",
        "to_account_number": "1212343433335665",
        "amount": "500.00",
        "status": "complete",
        "fail_reason": null
      }
    ]
  }
}
```
### Reset the database

```bash
docker compose down
rm -f storage/development.sqlite3
docker compose up --build
```

### Other handy endpoints

| Endpoint | Returns |
|---|---|
| `GET /accounts` | all accounts + current balances |
| `GET /transactions` | all transactions (status, fail reason, old balances) |
| `GET /transaction_files` | all uploaded files |
| `GET /up` | health check (200 when alive) |

---

Postman collection: [`postman/`](postman/Mable_Takehome.postman_collection.json)
