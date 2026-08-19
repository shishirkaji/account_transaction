desc "Load account balances from data/mable_account_balances.csv (clear-and-reload)"
task load_balances: :environment do
  path = Rails.root.join("data/mable_account_balances.csv")

  Account.delete_all

  File.readlines(path).each do |line|
    account_number, balance = line.strip.split(",")
    dollars, cents = balance.split(".")
    balance_cents = dollars.to_i * 100 + (cents || "0").ljust(2, "0").to_i

    Account.create!(account_number: account_number, balance_cents: balance_cents)
  end

  puts "Loaded #{Account.count} accounts"
end
