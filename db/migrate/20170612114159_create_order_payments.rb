class CreateOrderPayments < ActiveRecord::Migration[6.0]
  def change
    create_table :order_payments, :primary_key => :order_payment_id do |t|
      t.string :receipt_number, null:false
      t.integer :order_entry_id, null:false
      t.float :amount, default: 0.00
      t.integer :cashier, null: false
      t.boolean :voided, default: false
      t.integer :voided_by
      t.string :voided_reason
      t.timestamps null: false
    end
  end
end
