class CreateServicePriceHistories < ActiveRecord::Migration[6.0]
  def change
    create_table :service_price_histories, :primary_key => :price_history_id do |t|
      t.integer :service_id, null: false
      t.float :price, null: false, default: 0.0
      t.string :price_type, null: false
      t.date :active_from, null: false
      t.date :active_to
      t.integer :creator, null: false
      t.timestamps null: false
    end
  end
end
