class RemoveDemographicFlagsFromServices < ActiveRecord::Migration[6.0]
  def up
    remove_column :services, :child_allowed, :boolean, default: false, null: false
    remove_column :services, :male_allowed, :boolean, default: false, null: false
    remove_column :services, :female_allowed, :boolean, default: false, null: false
  end

  def down
    add_column :services, :child_allowed, :boolean, default: false, null: false
    add_column :services, :male_allowed, :boolean, default: false, null: false
    add_column :services, :female_allowed, :boolean, default: false, null: false
  end
end
