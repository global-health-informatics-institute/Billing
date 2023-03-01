class PersonName < ActiveRecord::Base
  #establish_connection Registration
  self.table_name = "person_name"
  self.primary_key = "person_name_id"

  include Openmrs

  before_create :before_create
  before_update :before_save
  before_save :before_save


  #default_scope {-> {order('person_name.preferred DESC')}}
  belongs_to :person, -> { where "voided = 0" }, :foreign_key => :person_id
  has_one :person_name_code, :foreign_key => :person_name_id # no default scope

  def before_create
    super
    code = PersonNameCode.where(person_name_id: self.person_name_id).first_or_initialize
    code.given_name_code = (self.given_name || '').soundex
    code.middle_name_code = (self.middle_name || '').soundex
    code.family_name_code = (self.family_name || '').soundex
    code.family_name2_code = (self.family_name2 || '').soundex
    code.family_name_suffix_code = (self.family_name_suffix || '').soundex
    code.save

    other_name = PersonName.where(person_id: self.person_id).first
    self.preferred = (other_name.blank? ? 1 : (other_name.preferred + 1))
  end

  def before_save
    super
    code = PersonNameCode.where(person_name_id: self.person_name_id).first_or_initialize
    code.given_name_code = (self.given_name || '').soundex
    code.middle_name_code = (self.middle_name || '').soundex
    code.family_name_code = (self.family_name || '').soundex
    code.family_name2_code = (self.family_name2 || '').soundex
    code.family_name_suffix_code = (self.family_name_suffix || '').soundex
    code.save
  end

  # Looks for the most commonly used element in the database and sorts the results based on the first part of the string
  def self.find_most_common(field_name, search_string)
    return self.find_by_sql([
                                "SELECT DISTINCT #{field_name} AS #{field_name}, #{self.primary_key} AS id \
     FROM person_name \
     INNER JOIN person ON person.person_id = person_name.person_id \
     WHERE person.voided = 0 AND person_name.voided = 0 AND #{field_name} LIKE ? \
     GROUP BY #{field_name} ORDER BY INSTR(#{field_name},\"#{search_string}\") ASC, COUNT(#{field_name}) DESC, #{field_name} ASC LIMIT 10", "%#{search_string}%"])
  end

end
