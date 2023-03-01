class CreateServicePanelDetails < ActiveRecord::Migration[6.0]
  def change
    create_table :service_panel_details, :primary_key => :panel_detail_id do |t|
      t.integer :service_panel_id
      t.integer :service_id
      t.float :quantity
      t.timestamps null: false
    end
  end
end
