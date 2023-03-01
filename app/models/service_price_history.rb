class ServicePriceHistory < ActiveRecord::Base
  belongs_to :service
  belongs_to :user, :foreign_key => :creator
end
