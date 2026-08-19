class ServiceSet < ActiveRecord::Base
  self.primary_key = :service_set_id

  default_scope { where(voided: false) }

  has_many :service_set_maps
  has_many :services, through: :service_set_maps

  validates :name, :creator, presence: true
end
