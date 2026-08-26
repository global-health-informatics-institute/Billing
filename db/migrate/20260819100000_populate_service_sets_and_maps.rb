class PopulateServiceSetsAndMaps < ActiveRecord::Migration[6.0]
  class ServiceSet < ActiveRecord::Base
    self.table_name = 'service_sets'
  end

  class ServiceSetMap < ActiveRecord::Base
    self.table_name = 'service_set_maps'
  end

  class Service < ActiveRecord::Base
    self.table_name = 'services'
  end

  def up
    creator_id = 1

    service_sets = [
      { name: 'under_5' },
      { name: 'male' },
      { name: 'female' }
    ]

    service_sets.each do |set_attrs|
      set = ServiceSet.where(name: set_attrs[:name]).first_or_initialize
      set.creator = creator_id
      set.save
    end

    ServiceSetMap.where(voided: false).delete_all

    Service.where(voided: false).find_each do |service|
      sets_to_add = []
      sets_to_add << 'under_5' if service.child_allowed
      sets_to_add << 'male' if service.male_allowed
      sets_to_add << 'female' if service.female_allowed

      sets_to_add.uniq.each do |set_name|
        set = ServiceSet.find_by(name: set_name)
        next unless set
        ServiceSetMap.create(service_set_id: set.service_set_id, service_id: service.service_id, creator: creator_id)
      end
    end
  end

  def down
    ServiceSetMap.where(voided: false).delete_all
    ServiceSet.where(name: ['under_5', 'male', 'female']).delete_all
  end
end
