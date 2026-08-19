class TransactionFilesController < ApplicationController
  MAX_FILE_SIZE = 1.megabyte

  def create
    if params[:file].nil?
      return render_error("INVALID_FILE_FORMAT", "file is required", :unprocessable_entity)
    end

    if params[:file].size > MAX_FILE_SIZE
      return render_error("FILE_SIZE_TOO_BIG", "file exceeds 1MB", :payload_too_large)
    end

    unless params[:file].original_filename.end_with?(".csv")
      return render_error("INVALID_FILE_FORMAT", "file must be a CSV", :unprocessable_entity)
    end

    file = TransactionFile.create_with_transactions(params[:file].read, name: params[:file].original_filename)
    file.transactions.each(&:process!)

    render json: { status: "SUCCESS",
                   data: { transaction_file: file.as_json,
                           transactions: file.transactions.map(&:as_json) } },
           status: :created
  rescue TransactionParseError => e
    render_error("FAILED_TO_PARSE_TRANSACTIONS", e.message, :unprocessable_entity)
  end

  def index
    render json: { status: "SUCCESS", data: TransactionFile.order(:id).map(&:as_json) }
  end

  private

  def render_error(status, error, http_status)
    render json: { status: status, error: error }, status: http_status
  end
end
