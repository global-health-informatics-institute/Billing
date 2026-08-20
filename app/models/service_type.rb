class ServiceType < ActiveRecord::Base
  #default_scope {-> { where "#{self.table_name}.retired = false" }}
  default_scope { where(retired: false) }
  has_many :services
  has_many :service_panels

  def top_ten_services
    services.order(:name).limit(10).pluck(:name)
  end

  def all_service_names
    services.order(:name).pluck(:name)
  end

  def child
    set = ServiceSet.find_by(name: 'under_5')
    return [] unless set
    set.services.where(service_type_id: service_type_id).order(:name).pluck(:name)
  end

  def male
    set = ServiceSet.find_by(name: 'male')
    return [] unless set
    set.services.where(service_type_id: service_type_id).order(:name).pluck(:name)
  end

  def female
    set = ServiceSet.find_by(name: 'female')
    return [] unless set
    set.services.where(service_type_id: service_type_id).order(:name).pluck(:name)
  end

  def number_of_services
    self.services.select("count(service_id) as count").first.count
  end
end
