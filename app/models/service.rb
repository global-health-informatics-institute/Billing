class Service < ActiveRecord::Base

  #default_scope {-> {order 'rank ASC, name ASC' }}
  default_scope { where(voided: false) }
  default_scope { order('rank ASC, name ASC') }
  has_many :service_prices
  has_many :service_price_histories
  belongs_to :service_type
  has_many :service_set_maps
  has_many :service_sets, through: :service_set_maps

  validates :service_type_id, :name, :creator, presence: true
  attr_accessor :category

  before_create :before_create

  def get_price(location)
    self.service_prices.select(:price,:price_id).where(price_type: location).first rescue nil
  end

  def before_create
    self.service_type_id= self.category if self.service_type_id.blank?
  end
end
