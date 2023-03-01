class UserRole < ActiveRecord::Base
  #establish_connection Registration
  self.table_name = :user_role
  #self.primary_keys = :role, :user_id
  include Openmrs

  before_create :before_create
  before_update :before_save
  before_save :before_save

  belongs_to :user, -> {where "retired = false"}, :foreign_key => :user_id
end
