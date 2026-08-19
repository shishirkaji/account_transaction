FactoryBot.define do
  factory :account do
    sequence(:account_number) { |n| format("%016d", n) }
    balance_cents { 0 }
    blocked { false }
    blocked_reason { nil }
  end
end
