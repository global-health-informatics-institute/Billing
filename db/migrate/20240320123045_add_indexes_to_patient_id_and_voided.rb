class AddIndexesToPatientIdAndVoided < ActiveRecord::Migration[6.0]
  def change
    add_index :receipts, :patient_id
    add_index :receipts, :voided
    add_index :receipts, :receipt_number
    add_index :receipts, :payment_stamp

    add_index :order_entries, :patient_id
    add_index :order_entries, :voided
    add_index :order_entries, :order_entry_id

    add_index :order_payments, :receipt_number
    add_index :order_payments, :voided
    add_index :order_payments, :order_entry_id
    add_index :order_payments, :order_payment_id
  end
end