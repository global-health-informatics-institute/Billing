class CreateMedicalSchemeProviders < ActiveRecord::Migration[6.0]
  def change
    create_table :medical_scheme_providers, :primary_key => 'scheme_provider_id' do |t|
      t.string :company_name
      t.string :company_address
      t.string :phone_number_1
      t.string :phone_number_2
      t.string :email_address
      t.integer :creator, null: false
      t.boolean :retired, null: false, default: false
      t.integer :retired_by
      t.string :retired_reason
      t.timestamps null: false
    end
  end
end
