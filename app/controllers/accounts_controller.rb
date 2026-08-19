class AccountsController < ApplicationController
  def index
    render json: { status: "SUCCESS", data: Account.order(:id).map(&:as_json) }
  end
end
