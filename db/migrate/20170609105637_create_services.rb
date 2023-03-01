class CreateServices < ActiveRecord::Migration[6.0]
  def change
    create_table :services, :primary_key => :service_id do |t|
      t.string :name, null: false
      t.integer :service_type_id, null: false
      t.string :unit
      t.integer :rank, null: false, default: 999
      t.integer :creator, null: false
      t.boolean :voided, default: false
      t.integer :voided_by
      t.string :voided_reason
      t.date :voided_date
      t.timestamps null: false
    end
  end
end
