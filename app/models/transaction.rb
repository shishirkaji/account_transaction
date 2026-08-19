class Transaction < ApplicationRecord
  belongs_to :transaction_file, optional: true

  enum :status, { pending: "pending", complete: "complete", failed: "failed" }, default: :pending

  before_destroy :prevent_destroy
  before_update :prevent_update_when_processed

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
