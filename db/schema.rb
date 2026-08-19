# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_19_145405) do
  create_table "accounts", force: :cascade do |t|
    t.string "account_number"
    t.integer "balance_cents", default: 0
    t.boolean "blocked", default: false
    t.string "blocked_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_number"], name: "index_accounts_on_account_number", unique: true
  end

  create_table "transaction_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_valid", default: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.datetime "uploaded_at"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "amount_cents"
    t.datetime "created_at", null: false
    t.string "fail_reason"
    t.string "from_account_number"
    t.integer "from_account_old_balance_cents"
    t.string "status", default: "pending"
    t.string "to_account_number"
    t.integer "to_account_old_balance_cents"
    t.integer "transaction_file_id"
    t.datetime "updated_at", null: false
    t.index ["from_account_number"], name: "index_transactions_on_from_account_number"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["to_account_number"], name: "index_transactions_on_to_account_number"
    t.index ["transaction_file_id"], name: "index_transactions_on_transaction_file_id"
  end

  add_foreign_key "transactions", "transaction_files"
end
