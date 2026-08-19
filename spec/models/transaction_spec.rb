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
end
