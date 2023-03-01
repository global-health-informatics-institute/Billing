class ServicePanel < ActiveRecord::Base
  #default_scope {-> { where "#{self.table_name}.voided = false"}}
  default_scope { where(voided: false) }
  has_many :service_panel_details
  belongs_to :service_type
end
