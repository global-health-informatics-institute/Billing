class CreateReceipts < ActiveRecord::Migration[6.0]
  def change
    create_table :receipts do |t|
      t.integer :patient_id
      t.string :receipt_number, null: false
      t.datetime :payment_stamp
      t.string :payment_mode, null: false, default: "CASH"
      t.integer :cashier, null: false
      t.boolean :voided, default: false
      t.integer :voided_by
      t.timestamps null: false
    end
  end
end
