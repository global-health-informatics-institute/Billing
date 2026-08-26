class AddDemographicFlagsToServices < ActiveRecord::Migration[6.1]
  class Service < ActiveRecord::Base
    self.table_name = 'services'
  end

  def up
    add_column :services, :child_allowed, :boolean, null: false, default: false
    add_column :services, :male_allowed, :boolean, null: false, default: false
    add_column :services, :female_allowed, :boolean, null: false, default: false

    Service.reset_column_information

    child_ids = [3, 7, 8, 9, 10]
    male_ids = [1, 6, 7, 8, 9, 10]
    female_ids = [2, 4, 5, 6, 7, 8, 9, 10]

    Service.where(service_id: child_ids).update_all(child_allowed: true)
    Service.where(service_id: male_ids).update_all(male_allowed: true)
    Service.where(service_id: female_ids).update_all(female_allowed: true)
  end

  def down
    remove_column :services, :child_allowed
    remove_column :services, :male_allowed
    remove_column :services, :female_allowed
  end
end
