require 'rails_helper'

RSpec.describe "TransactionFiles", type: :request do
  def upload(csv, filename: "day1.csv", content_type: "text/csv")
    file = Rack::Test::UploadedFile.new(StringIO.new(csv), content_type, original_filename: filename)
    post "/transaction_files", params: { file: file }
  end

  describe "POST /transaction_files" do
    it "returns 201 SUCCESS and processes a valid CSV, moving balances" do
      from = create(:account, account_number: "1111234522226789", balance_cents: 100000)
      to = create(:account, account_number: "1212343433335665", balance_cents: 50000)
      csv = "1111234522226789,1212343433335665,10.00\n"

      upload(csv)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("SUCCESS")
      expect(body["data"]["transactions"].first["status"]).to eq("complete")
      expect(from.reload.balance_cents).to eq(99000)
      expect(to.reload.balance_cents).to eq(51000)
    end

    it "returns 422 INVALID_FILE_FORMAT when the file param is missing" do
      post "/transaction_files"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["status"]).to eq("INVALID_FILE_FORMAT")
    end

    it "returns 413 FILE_SIZE_TOO_BIG for files over 1MB" do
      big_amount = "9" * (1_048_577)
      upload("1111234522226789,1212343433335665,#{big_amount}\n")

      expect(response).to have_http_status(:payload_too_large)
      expect(JSON.parse(response.body)["status"]).to eq("FILE_SIZE_TOO_BIG")
    end

    it "returns 422 INVALID_FILE_FORMAT for a non-CSV extension" do
      upload("1111234522226789,1212343433335665,500.00\n", filename: "day1.txt")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["status"]).to eq("INVALID_FILE_FORMAT")
    end

    it "returns 422 FAILED_TO_PARSE_TRANSACTIONS for a malformed CSV" do
      upload("1111234522226789,1212343433335665\n")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["status"]).to eq("FAILED_TO_PARSE_TRANSACTIONS")
    end

    it "shows the cascade over HTTP: one INSUFFICIENT_BALANCE then one ACCOUNT_BLOCKED" do
      create(:account, account_number: "1111234522226789", balance_cents: 1000)
      create(:account, account_number: "1212343433335665", balance_cents: 50000)
      csv = "1111234522226789,1212343433335665,1001.00\n1111234522226789,1212343433335665,100.00\n"

      upload(csv)

      expect(response).to have_http_status(:created)
      statuses = JSON.parse(response.body)["data"]["transactions"].map { |t| [t["status"], t["fail_reason"]] }
      expect(statuses).to eq([["failed", "INSUFFICIENT_BALANCE"], ["failed", "ACCOUNT_BLOCKED"]])
    end
  end
end
