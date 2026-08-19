class TransactionFilesController < ApplicationController
  MAX_FILE_SIZE = 1.megabyte

  def create
    if params[:file].nil?
      return render json: { status: "INVALID_FILE_FORMAT", error: "file is required" },
                    status: :unprocessable_entity
    end

    if params[:file].size > MAX_FILE_SIZE
      return render json: { status: "FILE_SIZE_TOO_BIG", error: "file exceeds 1MB" },
                    status: :payload_too_large
    end

    unless params[:file].original_filename.end_with?(".csv")
      return render json: { status: "INVALID_FILE_FORMAT", error: "file must be a CSV" },
                    status: :unprocessable_entity
    end

    file = TransactionFile.create_with_transactions(params[:file].read, name: params[:file].original_filename)
    file.transactions.each(&:process!)

    render json: { status: "SUCCESS",
                   data: { transaction_file: file.as_json,
                           transactions: file.transactions.map(&:as_json) } },
           status: :created
  rescue TransactionParseError => e
    render json: { status: "FAILED_TO_PARSE_TRANSACTIONS", error: e.message },
           status: :unprocessable_entity
  end
end
