class CreateDeposits < ActiveRecord::Migration[6.0]
  def change
    create_table :deposits, :primary_key => :deposit_id do |t|
      t.integer :patient_id, null:false
      t.float :amount_received, default: 0
      t.float :amount_available, default: 0
      t.integer :creator, null:false
      t.integer :updated_by
      t.boolean :voided, default: false
      t.integer :voided_by
      t.datetime :date_voided
      t.timestamps null: false
    end
  end
end
