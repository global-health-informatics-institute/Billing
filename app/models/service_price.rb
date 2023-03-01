class ServicePrice < ActiveRecord::Base
  #default_scope {-> { where "#{self.table_name}.voided = false" }}
  default_scope { where(voided: false) }
  belongs_to :service
  has_many :service_price_histories

  before_create :price_updated
  before_update :price_updated

  def price_updated
    last_price = ServicePriceHistory.where(:service_id => self.service_id,:price_type =>self.price_type ).last
    last_price.update(:active_to => Date.current) unless last_price.blank?

    ServicePriceHistory.create({:service_id => self.service_id, :price => self.price,
                                :price_type => self.price_type, :active_from => Date.current,
                                :creator => self.updated_by})
  end
end
