class Transaction < ApplicationRecord
  belongs_to :transaction_file

  enum :status, { pending: "pending", complete: "complete", failed: "failed" }, default: :pending
end
