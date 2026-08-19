# Ticket 04 — Test infrastructure: factory_bot + simplecov

**Status:** TODO
**Estimate:** ~10 min
**Depends on:** Ticket 02 (RSpec boots with AR)

## Goal
Stand up the two test tools locked in the POA: **factory_bot** (test data recipes) and **simplecov** (coverage %). After this ticket, both are wired and visibly working.

## You'll know it worked when (deliverable)
`bundle exec rspec` exits 0 AND the output ends with a line like:
```
Coverage report generated for RSpec - 0 / 0 LOC (100.0%) covered.
```

## Tasks
- [ ] `bundle add factory_bot_rails --group "development, test"`
- [ ] `bundle add simplecov --group test`
- [ ] At the very top of `spec/spec_helper.rb` (before everything else), add:
  ```ruby
  require "simplecov"
  SimpleCov.start
  ```
- [ ] In `spec/rails_helper.rb`, uncomment the block that requires files from `spec/support` (the `Dir[Rails.root.join("spec/support/**/*.rb")]` line)
- [ ] Create `spec/support/factory_bot.rb`:
  ```ruby
  RSpec.configure do |config|
    config.include FactoryBot::Syntax::Methods
  end
  ```
- [ ] Run `bundle exec rspec`

## Acceptance criteria
- [ ] `Gemfile.lock` contains `factory_bot_rails` and `simplecov`
- [ ] `bundle exec rspec` → `0 examples, 0 failures`, exit code 0
- [ ] SimpleCov "Coverage report generated" line appears in output
- [ ] The generated `spec/models/account_spec.rb` pending example still shows as pending (not failing) — it gets real content in Ticket 05

## Files touched
- `Gemfile`, `Gemfile.lock`
- `spec/spec_helper.rb`
- `spec/rails_helper.rb`
- `spec/support/factory_bot.rb` (new)

## Tests required
- None (infrastructure — the deliverable IS the test runner + coverage working)

## Definition of done
RSpec runs green with coverage reporting, and `create(:account)`-style factory syntax is available in every spec.

## Out of scope
- The `:account` factory itself (Ticket 05)
- Model validations (Ticket 05)
