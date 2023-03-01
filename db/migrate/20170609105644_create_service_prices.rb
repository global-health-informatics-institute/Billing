class CreateServicePrices < ActiveRecord::Migration[6.0]
  def change
    create_table :service_prices, :primary_key => :price_id do |t|
      t.integer :service_id, null: false
      t.float :price, null: false, default: 0.0
      t.string :price_type, null: false
      t.integer :creator, null: false
      t.integer :updated_by, null: false
      t.boolean :voided, default: false
      t.date :voided_date
      t.timestamps null: false
    end
  end
end
