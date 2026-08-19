#!/usr/bin/env python3
"""Verify a transaction dataset processes correctly end-to-end.

Simulates the app's business rules independently from the raw CSVs, then
compares against the live API. Run with the server up (docker compose up).

Usage:
    python3 scripts/verify_transactions.py [--balances FILE] [--transactions FILE]

Exit code 0 = all checks pass.
"""
import argparse
import json
import sys
import urllib.request
from collections import Counter

BASE = "http://localhost:3000"
DEFAULT_BALANCES = "data/mable_account_balances_50.csv"
DEFAULT_TRANSACTIONS = "data/mable_transactions_100.csv"


def parse_balance(bal):
    d, c = bal.split(".")
    return int(d) * 100 + int(c)


def parse_amount(amt):
    d, c = amt.split(".")
    return int(d) * 100 + int((c or "0").ljust(2, "0"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--balances", default=DEFAULT_BALANCES)
    parser.add_argument("--transactions", default=DEFAULT_TRANSACTIONS)
    args = parser.parse_args()

    # ---------- independent simulation ----------

    balances = {}
    for line in open(args.balances):
        num, bal = line.strip().split(",")
        balances[num] = parse_balance(bal)

    original_total = sum(balances.values())
    rows = [l.strip() for l in open(args.transactions) if l.strip()]

    expected = []          # (status, fail_reason)
    blocked_set = set()    # accounts blocked mid-batch (cascade source)
    for row in rows:
        frm, to, amt = row.split(",")
        amount = parse_amount(amt)

        if frm not in balances or to not in balances:
            expected.append(("failed", "ACCOUNT_NOT_FOUND"))
            continue
        if frm in blocked_set:
            expected.append(("failed", "ACCOUNT_BLOCKED"))
            continue
        if amount > balances[frm]:
            expected.append(("failed", "INSUFFICIENT_BALANCE"))
            blocked_set.add(frm)
            continue
        balances[frm] -= amount
        balances[to] += amount
        expected.append(("complete", None))

    expected_balances = balances
    expect_counts = dict(Counter(reason or status for status, reason in expected))

    # ---------- fetch live results ----------

    def get(path):
        with urllib.request.urlopen(BASE + path) as r:
            return json.load(r)

    with open(args.transactions, "rb") as f:
        boundary = "----verifyboundary"
        filename = args.transactions.split("/")[-1]
        body = b"".join([
            f"--{boundary}\r\n".encode(),
            f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'.encode(),
            b"Content-Type: text/csv\r\n\r\n",
            f.read(),
            f"\r\n--{boundary}--\r\n".encode(),
        ])
        req = urllib.request.Request(
            BASE + "/transaction_files", data=body,
            headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
        with urllib.request.urlopen(req) as r:
            uploaded = json.load(r)

    actual = [(t["status"], t["fail_reason"]) for t in uploaded["data"]["transactions"]]
    actual_balances = {a["account_number"]: parse_balance(a["balance"]) for a in get("/accounts")["data"]}

    # ---------- checks ----------

    failures = []

    if uploaded["status"] != "SUCCESS":
        failures.append(f"API status: {uploaded['status']} (expected SUCCESS)")

    if len(actual) != len(expected):
        failures.append(f"transaction count: {len(actual)} (expected {len(expected)})")

    for i, (a, e) in enumerate(zip(actual, expected)):
        if a != e:
            failures.append(f"row {i+1}: got {a}, expected {e}")
            break

    counts = dict(Counter(reason or status for status, reason in actual))
    if counts != expect_counts:
        failures.append(f"outcome counts: {counts} (expected {expect_counts})")

    if actual_balances != expected_balances:
        for num in sorted(set(actual_balances) | set(expected_balances)):
            if actual_balances.get(num) != expected_balances.get(num):
                failures.append(f"balance {num}: got {actual_balances.get(num)}, expected {expected_balances.get(num)}")
                break

    if sum(actual_balances.values()) != original_total:
        failures.append(
            f"money conservation: total {sum(actual_balances.values())} != original {original_total}")

    blocked = {a["account_number"] for a in get("/accounts")["data"] if a["blocked"]}
    if blocked != blocked_set:
        failures.append(f"blocked accounts: {blocked} (expected {blocked_set})")

    # ---------- report ----------

    print("=" * 60)
    print(f"VERIFICATION REPORT — {filename} ({len(rows)} transactions)")
    print("=" * 60)
    print(f"outcomes: {counts}")
    print(f"blocked accounts: {len(blocked)}")
    print(f"money conserved: {'✓' if sum(actual_balances.values()) == original_total else '✗'}")
    print(f"per-transaction match: {'✓' if actual == expected else '✗'}")
    print(f"final balances match simulation: {'✓' if actual_balances == expected_balances else '✗'}")
    print("-" * 60)
    if failures:
        print(f"FAILED ({len(failures)} issues):")
        for f_ in failures:
            print(f"  ✗ {f_}")
        sys.exit(1)
    else:
        print("ALL CHECKS PASSED ✓")
        sys.exit(0)


if __name__ == "__main__":
    main()
