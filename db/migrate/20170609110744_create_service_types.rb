class CreateServiceTypes < ActiveRecord::Migration[6.0]
  def change
    create_table :service_types,:primary_key => :service_type_id do |t|
      t.string :name, null: false
      t.integer :creator, null: false
      t.boolean :retired, null: false, default: false
      t.integer :retired_by
      t.string :retired_reason
      t.timestamps null: false
    end
  end
end
