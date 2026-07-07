class AddIndexesToPatientIdAndVoided < ActiveRecord::Migration[6.0]
  def change
    add_index :receipts, :patient_id
    add_index :receipts, :voided
    add_index :receipts, :receipt_number
    add_index :receipts, :payment_stamp

    add_index :order_entries, :patient_id
    add_index :order_entries, :voided
<<<<<<< HEAD
    add_index :order_entries, :order_entry_id
=======
>>>>>>> 057fb68b34cbfd6a1c4dee663a35c0a071aa6498

    add_index :order_payments, :receipt_number
    add_index :order_payments, :voided
    add_index :order_payments, :order_entry_id
    add_index :order_payments, :order_payment_id
  end
<<<<<<< HEAD
end
=======
end
>>>>>>> 057fb68b34cbfd6a1c4dee663a35c0a071aa6498
