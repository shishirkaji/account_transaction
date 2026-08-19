require 'rails_helper'

RSpec.describe Account, type: :model do
  describe "validations" do
    it "is valid with a factory account" do
      expect(build(:account)).to be_valid
    end

    it "is invalid without an account_number" do
      account = build(:account, account_number: nil)
      expect(account).to be_invalid
      expect(account.errors[:account_number]).to be_present
    end

    it "is invalid with 15 digits" do
      account = build(:account, account_number: "123456789012345")
      expect(account).to be_invalid
    end

    it "is invalid with 17 digits" do
      account = build(:account, account_number: "12345678901234567")
      expect(account).to be_invalid
    end

    it "is invalid with non-digit characters" do
      account = build(:account, account_number: "123456789012345a")
      expect(account).to be_invalid
    end

    it "is invalid with a duplicate account_number" do
      create(:account, account_number: "1111234522226789")
      duplicate = build(:account, account_number: "1111234522226789")
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:account_number]).to be_present
    end
  end

  describe "#add_balance" do
    it "increases the balance and returns the new balance" do
      account = create(:account, balance_cents: 500000)

      new_balance = account.add_balance(50000)

      expect(new_balance).to eq(550000)
      expect(account.reload.balance_cents).to eq(550000)
    end
  end

  describe "#deduct_balance" do
    it "decreases the balance and returns the new balance" do
      account = create(:account, balance_cents: 500000)

      new_balance = account.deduct_balance(50000)

      expect(new_balance).to eq(450000)
      expect(account.reload.balance_cents).to eq(450000)
    end

    it "allows deducting exactly to zero" do
      account = create(:account, balance_cents: 50000)

      new_balance = account.deduct_balance(50000)

      expect(new_balance).to eq(0)
      expect(account.reload.balance_cents).to eq(0)
    end

    it "raises InsufficientBalanceError when it would go below zero and leaves the balance unchanged" do
      account = create(:account, balance_cents: 50000)

      expect { account.deduct_balance(50001) }.to raise_error(InsufficientBalanceError)
      expect(account.reload.balance_cents).to eq(50000)
    end
  end

  describe "#block" do
    it "sets blocked and blocked_reason, and returns nil" do
      account = create(:account)

      result = account.block("fraud")

      expect(result).to be_nil
      expect(account.reload).to be_blocked
      expect(account.reload.blocked_reason).to eq("fraud")
    end
  end
end
