class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :transaction_file, null: false, foreign_key: true
      t.string :from_account_number
      t.string :to_account_number
      t.integer :amount_cents
      t.string :status, default: "pending"
      t.string :fail_reason
      t.integer :from_account_old_balance_cents
      t.integer :to_account_old_balance_cents

      t.timestamps
    end
    add_index :transactions, :from_account_number
    add_index :transactions, :to_account_number
    add_index :transactions, :status
  end
end
