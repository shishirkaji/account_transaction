require 'rails_helper'

RSpec.describe TransactionFile, type: :model do
  describe ".create_with_transactions" do
    it "creates a valid file with ordered pending transactions from a valid CSV" do
      csv = "1111234522226789,1212343433335665,500.00\n3212343433335755,2222123433331212,1000.00\n"

      file = TransactionFile.create_with_transactions(csv, name: "day1.csv")

      expect(file).to be_is_valid
      expect(file.name).to eq("day1.csv")
      transactions = file.transactions
      expect(transactions.map(&:from_account_number)).to eq(["1111234522226789", "3212343433335755"])
      expect(transactions.map(&:to_account_number)).to eq(["1212343433335665", "2222123433331212"])
      expect(transactions.map(&:amount_cents)).to eq([50000, 100000])
      expect(transactions.map(&:status)).to all(eq("pending"))
    end

    it "parses whole-dollar amounts without decimals" do
      file = TransactionFile.create_with_transactions("1111234522226789,1212343433335665,500\n", name: "day1.csv")

      expect(file.transactions.first.amount_cents).to eq(50000)
    end

    it "raises TransactionParseError on wrong column count, creating no transactions" do
      csv = "1111234522226789,1212343433335665,500.00\n3212343433335755,2222123433331212\n"

      expect { TransactionFile.create_with_transactions(csv, name: "bad.csv") }
        .to raise_error(TransactionParseError)

      file = TransactionFile.find_by(name: "bad.csv")
      expect(file).not_to be_is_valid
      expect(file.transactions.count).to eq(0)
    end

    it "raises on too many columns (regression: 4-column row was silently accepted)" do
      csv = "a,b,500.00,extra\n"

      expect { TransactionFile.create_with_transactions(csv, name: "bad.csv") }
        .to raise_error(TransactionParseError, /expected 3 columns, got 4/)
    end

    it "raises on a trailing comma (regression: was silently accepted)" do
      csv = "1111234522226789,1212343433335665,500.00,\n"

      expect { TransactionFile.create_with_transactions(csv, name: "bad.csv") }
        .to raise_error(TransactionParseError)
    end

    it "raises TransactionParseError on non-numeric amount, creating no transactions" do
      csv = "1111234522226789,1212343433335665,abc\n"

      expect { TransactionFile.create_with_transactions(csv, name: "bad.csv") }
        .to raise_error(TransactionParseError)
      expect(TransactionFile.find_by(name: "bad.csv").transactions.count).to eq(0)
    end

    it "raises TransactionParseError on negative or zero amount, creating no transactions" do
      ["-5.00", "0.00"].each do |amount|
        csv = "1111234522226789,1212343433335665,#{amount}\n"

        expect { TransactionFile.create_with_transactions(csv, name: "bad.csv") }
          .to raise_error(TransactionParseError)
        expect(TransactionFile.find_by(name: "bad.csv").transactions.count).to eq(0)
      end
    end

    it "skips blank lines" do
      csv = "1111234522226789,1212343433335665,500.00\n\n3212343433335755,2222123433331212,1000.00\n"

      file = TransactionFile.create_with_transactions(csv, name: "day1.csv")

      expect(file.transactions.count).to eq(2)
    end
  end
end
