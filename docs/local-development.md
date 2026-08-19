# Run without Docker

Local development for **Bank Transaction** — use this instead of the Docker
quick start when you already have Ruby set up.

## Requirements

- Ruby 4.0.6 (via rbenv or your preferred manager)
- Bundler
- SQLite 3 (macOS ships it)

## Setup

```bash
bundle install
bin/rails db:migrate
bin/rails load_balances    # loads balances from data/mable_account_balances.csv
```

`db:migrate` creates `storage/development.sqlite3`. `load_balances` clears and
reloads accounts from the CSV — safe to re-run anytime.

## Run

```bash
bin/rails server
```

API listens on <http://localhost:3000>.

## Test

```bash
bundle exec rspec
bin/rubocop
```

## Custom balances

Drop your own CSV (one `account_number,balance` per line) at
`data/mable_account_balances.csv`, then:

```bash
bin/rails load_balances
```

Bundled datasets: `data/mable_account_balances_50.csv` (50 accounts) ·
`data/mable_transactions_100.csv` (100 diverse transfers).

## Reset the database

```bash
bin/rails load_balances            # reset data only (accounts/balances/blocks)
bin/rails db:drop db:create db:migrate && bin/rails load_balances   # full reset
```
