class Transaction < ApplicationRecord
  belongs_to :transaction_file, optional: true

  enum :status, { pending: "pending", complete: "complete", failed: "failed" }, default: :pending

  before_destroy :prevent_destroy
  before_update :prevent_update_when_processed

  def process!
    raise "Transaction only gets processed once" unless pending?

    from_account = Account.find_by(account_number: from_account_number)
    to_account = Account.find_by(account_number: to_account_number)

    self.from_account_old_balance_cents = from_account&.balance_cents
    self.to_account_old_balance_cents = to_account&.balance_cents

    if from_account.nil? || to_account.nil?
      return fail("ACCOUNT_NOT_FOUND")
    end

    if from_account.blocked?
      return fail("ACCOUNT_BLOCKED")
    end

    ActiveRecord::Base.transaction do
      begin
        from_account.deduct_balance(amount_cents)
      rescue InsufficientBalanceError
        from_account.block("insufficient balance")
        return fail("INSUFFICIENT_BALANCE")
      end

      to_account.reload
      to_account.add_balance(amount_cents)
      complete
    end
  end

  def fail(reason)
    update!(status: :failed, fail_reason: reason)
  end

  def complete
    update!(status: :complete)
  end

  private

  def prevent_destroy
    errors.add(:base, "transactions can never be deleted")
    throw :abort
  end

  def prevent_update_when_processed
    return if status_was == "pending"

    errors.add(:base, "processed transactions are immutable")
    throw :abort
  end
end
