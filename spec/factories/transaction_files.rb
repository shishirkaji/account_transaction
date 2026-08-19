FactoryBot.define do
  factory :transaction_file do
    name { "day1.csv" }
    uploaded_at { Time.utc(2026, 8, 20) }
    is_valid { false }
  end
end
