class CreateTransactionFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_files do |t|
      t.string :name
      t.datetime :uploaded_at
      t.boolean :is_valid, default: false

      t.timestamps
    end
  end
end
