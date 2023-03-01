class ServiceType < ActiveRecord::Base
  #default_scope {-> { where "#{self.table_name}.retired = false" }}
  default_scope { where(retired: false) }
  has_many :services
  has_many :service_panels

  def top_ten_services
    self.services.select(:name).limit(10).collect{|x| x.name}
  end

  def number_of_services
    self.services.select("count(service_id) as count").first.count
  end
end
