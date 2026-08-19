class Account < ApplicationRecord
  validates :account_number, presence: true,
                             format: { with: /\A\d{16}\z/ },
                             uniqueness: true
end
