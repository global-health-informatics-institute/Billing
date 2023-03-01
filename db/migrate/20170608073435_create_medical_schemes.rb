class CreateMedicalSchemes < ActiveRecord::Migration[6.0]
  def change
    create_table :medical_schemes, :primary_key => 'medical_scheme_id' do |t|
      t.string :name, null: false
      t.integer :medical_scheme_provider, null: false
      t.integer :creator, null: false
      t.boolean :retired, null: false, default: false
      t.integer :retired_by
      t.string :retired_reason
      t.timestamps null: false
    end
  end
end
