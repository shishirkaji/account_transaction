class TransactionFile < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error
end
