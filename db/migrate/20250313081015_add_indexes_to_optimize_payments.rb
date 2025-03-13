class AddIndexesToOptimizePayments < ActiveRecord::Migration[6.1]
  def change
    add_index :order_entries, :order_entry_id
    add_index :order_entries, :patient_id
    add_index :order_entries, :voided
    add_index :order_payments, :receipt_number
    add_index :order_payments, :order_entry_id
  end
end