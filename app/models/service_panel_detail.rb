class ServicePanelDetail < ActiveRecord::Base
  has_one :service
  belongs_to :service_panel
end
