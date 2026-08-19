require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe "append-only ledger" do
    it "can never be deleted once created" do
      transaction = create(:transaction)

      expect { transaction.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(Transaction.exists?(transaction.id)).to be(true)
    end

    it "can be updated while still pending" do
      transaction = create(:transaction)

      expect { transaction.update!(amount_cents: 2000) }.not_to raise_error
      expect(transaction.reload.amount_cents).to eq(2000)
    end

    it "can transition from pending to complete" do
      transaction = create(:transaction)

      expect { transaction.update!(status: :complete) }.not_to raise_error
      expect(transaction.reload).to be_complete
    end

    it "can transition from pending to failed" do
      transaction = create(:transaction)

      expect { transaction.update!(status: :failed, fail_reason: "ACCOUNT_BLOCKED") }.not_to raise_error
      expect(transaction.reload).to be_failed
    end

    it "cannot be updated once it leaves pending" do
      transaction = create(:transaction, status: :complete)

      expect { transaction.update!(amount_cents: 9999) }.to raise_error(ActiveRecord::RecordNotSaved)
      expect(transaction.reload.amount_cents).to eq(1000)
    end

    it "cannot change status once complete" do
      transaction = create(:transaction, status: :complete)

      expect { transaction.update!(status: :pending) }.to raise_error(ActiveRecord::RecordNotSaved)
      expect(transaction.reload).to be_complete
    end
  end

  describe "#process!" do
    it "moves funds and records old balances on the happy path" do
      from = create(:account, account_number: "1111234522226789", balance_cents: 100000)
      to = create(:account, account_number: "1212343433335665", balance_cents: 50000)
      transaction = create(:transaction, from_account_number: from.account_number,
                                         to_account_number: to.account_number,
                                         amount_cents: 1000)

      transaction.process!

      expect(from.reload.balance_cents).to eq(99000)
      expect(to.reload.balance_cents).to eq(51000)
      expect(transaction.reload).to be_complete
      expect(transaction.from_account_old_balance_cents).to eq(100000)
      expect(transaction.to_account_old_balance_cents).to eq(50000)
    end

    it "raises when the transaction is not pending (only processes once)" do
      transaction = create(:transaction, status: :complete)

      expect { transaction.process! }.to raise_error("Transaction only gets processed once")
    end

    it "fails with ACCOUNT_BLOCKED when the from-account is blocked, leaving balances untouched" do
      from = create(:account, account_number: "1111234522226789", balance_cents: 100000, blocked: true,
                              blocked_reason: "fraud")
      to = create(:account, account_number: "1212343433335665", balance_cents: 50000)
      transaction = create(:transaction, from_account_number: from.account_number,
                                         to_account_number: to.account_number,
                                         amount_cents: 1000)

      transaction.process!

      expect(transaction.reload).to be_failed
      expect(transaction.fail_reason).to eq("ACCOUNT_BLOCKED")
      expect(from.reload.balance_cents).to eq(100000)
      expect(to.reload.balance_cents).to eq(50000)
    end

    it "fails with INSUFFICIENT_BALANCE and blocks the from-account" do
      from = create(:account, account_number: "1111234522226789", balance_cents: 1000)
      to = create(:account, account_number: "1212343433335665", balance_cents: 50000)
      transaction = create(:transaction, from_account_number: from.account_number,
                                         to_account_number: to.account_number,
                                         amount_cents: 1001)

      transaction.process!

      expect(transaction.reload).to be_failed
      expect(transaction.fail_reason).to eq("INSUFFICIENT_BALANCE")
      expect(from.reload).to be_blocked
      expect(from.reload.blocked_reason).to eq("insufficient balance")
      expect(to.reload.balance_cents).to eq(50000)
    end

    it "cascades: a second transaction from the now-blocked account fails with ACCOUNT_BLOCKED" do
      from = create(:account, account_number: "1111234522226789", balance_cents: 1000)
      to = create(:account, account_number: "1212343433335665", balance_cents: 50000)
      first = create(:transaction, from_account_number: from.account_number,
                                   to_account_number: to.account_number,
                                   amount_cents: 1001)
      second = create(:transaction, from_account_number: from.account_number,
                                    to_account_number: to.account_number,
                                    amount_cents: 100)

      first.process!
      second.process!

      expect(first.reload.fail_reason).to eq("INSUFFICIENT_BALANCE")
      expect(second.reload).to be_failed
      expect(second.fail_reason).to eq("ACCOUNT_BLOCKED")
    end

    it "still completes when the to-account is blocked (blocked accounts can receive)" do
      from = create(:account, account_number: "1111234522226789", balance_cents: 100000)
      to = create(:account, account_number: "1212343433335665", balance_cents: 50000, blocked: true,
                            blocked_reason: "fraud")
      transaction = create(:transaction, from_account_number: from.account_number,
                                         to_account_number: to.account_number,
                                         amount_cents: 1000)

      transaction.process!

      expect(transaction.reload).to be_complete
      expect(to.reload.balance_cents).to eq(51000)
    end

    it "fails with ACCOUNT_NOT_FOUND when an account is missing" do
      to = create(:account, account_number: "1212343433335665", balance_cents: 50000)
      transaction = create(:transaction, from_account_number: "9999999999999999",
                                         to_account_number: to.account_number,
                                         amount_cents: 1000)

      transaction.process!

      expect(transaction.reload).to be_failed
      expect(transaction.fail_reason).to eq("ACCOUNT_NOT_FOUND")
      expect(to.reload.balance_cents).to eq(50000)
    end

    it "allows self-transfers (net zero) when funds are sufficient" do
      account = create(:account, account_number: "1111234522226789", balance_cents: 100000)
      transaction = create(:transaction, from_account_number: account.account_number,
                                         to_account_number: account.account_number,
                                         amount_cents: 1000)

      transaction.process!

      expect(transaction.reload).to be_complete
      expect(account.reload.balance_cents).to eq(100000)
    end

    it "rolls back everything when crediting the to-account raises" do
      from = create(:account, account_number: "1111234522226789", balance_cents: 100000)
      to = create(:account, account_number: "1212343433335665", balance_cents: 50000)
      transaction = create(:transaction, from_account_number: from.account_number,
                                         to_account_number: to.account_number,
                                         amount_cents: 1000)
      allow(Account).to receive(:find_by).with(account_number: from.account_number).and_return(from)
      allow(Account).to receive(:find_by).with(account_number: to.account_number).and_return(to)
      allow(to).to receive(:add_balance).and_raise("boom")

      expect { transaction.process! }.to raise_error("boom")

      expect(from.reload.balance_cents).to eq(100000)
      expect(to.reload.balance_cents).to eq(50000)
      expect(transaction.reload).to be_pending
    end
  end
end
