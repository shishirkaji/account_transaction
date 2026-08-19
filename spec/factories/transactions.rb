FactoryBot.define do
  factory :transaction do
    transaction_file { nil }
    from_account_number { "1111234522226789" }
    to_account_number { "1212343433335665" }
    amount_cents { 1000 }
  end
end
