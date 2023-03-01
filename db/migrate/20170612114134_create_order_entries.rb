class CreateOrderEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :order_entries,:primary_key => :order_entry_id do |t|
      t.integer :patient_id, null: false
      t.integer :service_id, null: false
      t.datetime :order_date, null: false
      t.float :quantity, null: false, default: 0
      t.float :full_price, null: false, default: 0
      t.float :amount_paid, null: false, default: 0
      t.integer :cashier, null: false
      t.integer :location, nul: false
      t.boolean :voided, default: false
      t.integer :voided_by
      t.string :voided_reason
      t.timestamps null: false
    end
  end
end
