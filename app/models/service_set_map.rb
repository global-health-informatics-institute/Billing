class ServiceSetMap < ActiveRecord::Base
  self.primary_key = :service_set_map_id

  default_scope { where(voided: false) }

  belongs_to :service_set
  belongs_to :service

  validates :service_set_id, :service_id, :creator, presence: true
end
