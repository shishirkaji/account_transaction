class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :account_number
      t.integer :balance_cents, default: 0
      t.boolean :blocked, default: false
      t.string :blocked_reason

      t.timestamps
    end
    add_index :accounts, :account_number, unique: true
  end
end
