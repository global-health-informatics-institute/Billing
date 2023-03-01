class CreatePatientAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :patient_accounts, :primary_key => 'account_id' do |t|
      t.integer :patient_id, null: false
      t.integer :medical_scheme_id, null: false
      t.date :active_from, null: :false
      t.boolean :active, default: true
      t.integer :creator, null: false
      t.timestamps null: false
    end
  end
end
