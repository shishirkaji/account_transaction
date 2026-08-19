require 'rails_helper'

RSpec.describe "Transactions", type: :request do
  describe "GET /transactions" do
    it "returns transactions with curated JSON in the envelope" do
      file = create(:transaction_file)
      create(:transaction, transaction_file: file,
                           from_account_number: "1111234522226789",
                           to_account_number: "1212343433335665",
                           amount_cents: 50000,
                           status: :complete,
                           from_account_old_balance_cents: 500000,
                           to_account_old_balance_cents: 120000)
      create(:transaction, transaction_file: file,
                           from_account_number: "1111234522226789",
                           to_account_number: "1212343433335665",
                           amount_cents: 1000,
                           status: :failed,
                           fail_reason: "INSUFFICIENT_BALANCE")

      get "/transactions"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("SUCCESS")
      transactions = body["data"]
      expect(transactions.length).to eq(2)

      complete = transactions.find { |t| t["status"] == "complete" }
      expect(complete).to eq({
        "id" => complete["id"],
        "from_account_number" => "1111234522226789",
        "to_account_number" => "1212343433335665",
        "amount" => "500.00",
        "status" => "complete",
        "fail_reason" => nil,
        "from_account_old_balance" => "5000.00",
        "to_account_old_balance" => "1200.00"
      })

      failed = transactions.find { |t| t["status"] == "failed" }
      expect(failed["amount"]).to eq("10.00")
      expect(failed["fail_reason"]).to eq("INSUFFICIENT_BALANCE")
    end

    it "does not leak raw cents or timestamps" do
      create(:transaction)

      get "/transactions"

      transaction = JSON.parse(response.body)["data"].first
      expect(transaction.keys).to contain_exactly("id", "from_account_number", "to_account_number",
                                                  "amount", "status", "fail_reason",
                                                  "from_account_old_balance", "to_account_old_balance")
    end

    it "returns an empty array when there are no transactions" do
      get "/transactions"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]).to eq([])
    end
  end
end
