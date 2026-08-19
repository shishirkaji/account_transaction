FactoryBot.define do
  factory :transaction do
    transaction_file { nil }
    from_account_number { "MyString" }
    to_account_number { "MyString" }
    amount_cents { 1 }
    status { "MyString" }
    fail_reason { "MyString" }
    from_account_old_balance_cents { 1 }
    to_account_old_balance_cents { 1 }
  end
end
