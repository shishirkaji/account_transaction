require 'rails_helper'

RSpec.describe "Accounts", type: :request do
  describe "GET /accounts" do
    it "returns accounts with curated JSON in the envelope" do
      create(:account, account_number: "1111234522226789", balance_cents: 500000)
      create(:account, account_number: "1111234522221234", balance_cents: 1000000, blocked: true,
                       blocked_reason: "fraud")

      get "/accounts"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("SUCCESS")
      accounts = body["data"]
      expect(accounts.length).to eq(2)
      expect(accounts.first).to eq({
        "account_number" => "1111234522226789",
        "balance" => "5000.00",
        "blocked" => false,
        "blocked_reason" => nil
      })
      expect(accounts.last["balance"]).to eq("10000.00")
      expect(accounts.last["blocked_reason"]).to eq("fraud")
    end

    it "does not leak raw cents, ids, or timestamps" do
      create(:account)

      get "/accounts"

      account = JSON.parse(response.body)["data"].first
      expect(account.keys).to contain_exactly("account_number", "balance", "blocked", "blocked_reason")
    end

    it "returns an empty array when there are no accounts" do
      get "/accounts"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]).to eq([])
    end
  end
end
