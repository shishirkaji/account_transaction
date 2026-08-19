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
end
