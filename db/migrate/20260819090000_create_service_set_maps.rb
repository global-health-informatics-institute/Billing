class CreateServiceSetMaps < ActiveRecord::Migration[6.0]
  def change
    create_table :service_set_maps, :primary_key => :service_set_map_id do |t|
      t.integer :service_set_id, null: false
      t.integer :service_id, null: false
      t.integer :creator, null: false
      t.boolean :voided, default: false
      t.integer :voided_by
      t.string :voided_reason
      t.date :voided_date
      t.timestamps null: false
    end

    add_index :service_set_maps, [:service_set_id, :service_id]
    add_index :service_set_maps, :service_set_id
    add_index :service_set_maps, :service_id
  end
end
