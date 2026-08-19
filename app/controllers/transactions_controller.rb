class TransactionsController < ApplicationController
  def index
    render json: { status: "SUCCESS", data: Transaction.order(:id).map(&:as_json) }
  end
end
