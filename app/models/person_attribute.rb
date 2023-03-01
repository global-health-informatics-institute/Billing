class PersonAttribute < ActiveRecord::Base
  #establish_connection Registration

  self.table_name = "person_attribute"
  self.primary_key = "person_attribute_id"
  include Openmrs

  before_create :before_create
  before_update :before_save
  before_save :before_save

  belongs_to :type, -> {where "retired = false"}, :class_name => "PersonAttributeType", :foreign_key => :person_attribute_type_id
  belongs_to :person, -> {where "retired = false"}, :foreign_key => :person_id

end
