class UserProperty < ActiveRecord::Base
  #establish_connection Registration
  self.table_name = "user_property"
  self.primary_key = :user_id, :property
  include Openmrs

  before_create :before_create
  before_update :before_save
  before_save :before_save

  belongs_to :user,-> {where ("voided => false")}, :foreign_key => :user_id

end
