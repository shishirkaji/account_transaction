source "https://rubygems.org"

gem "rails", "~> 8.1.3", ">= 8.1.3.1"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false
gem "thruster", require: false
gem "sqlite3"
gem "csv"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails", "~> 8.0"
end

gem "factory_bot_rails", "~> 6.5", groups: [:development, :test]

gem "simplecov", "~> 1.1", group: :test
