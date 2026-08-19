class Account < ApplicationRecord
  validates :account_number, presence: true,
                             format: { with: /\A\d{16}\z/ },
                             uniqueness: true

  def add_balance(amount_cents)
    self.balance_cents += amount_cents
    save!
    balance_cents
  end

  def deduct_balance(amount_cents)
    raise InsufficientBalanceError if amount_cents > balance_cents

    self.balance_cents -= amount_cents
    save!
    balance_cents
  end

  def block(reason)
    update!(blocked: true, blocked_reason: reason)
    nil
  end
end
