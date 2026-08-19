class TransactionFile < ApplicationRecord
  has_many :transactions, dependent: :destroy
end
