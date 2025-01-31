class PersonNameCode < ActiveRecord::Base
  #establish_connection Registration
  self.table_name = "person_name_code"
  self.primary_key = "person_name_code_id"

  include Openmrs

  #belongs_to :person_name, :conditions => {:voided => 0}

  def self.rebuild_person_name_codes
    PersonNameCode.delete_all
    names = PersonName.all
    names.each {|name|
      PersonNameCode.create(
          :person_name_id => name.person_name_id,
          :given_name_code => (name.given_name || '').soundex,
          :middle_name_code => (name.middle_name || '').soundex,
          :family_name_code => (name.family_name || '').soundex,
          :family_name2_code => (name.family_name2 || '').soundex,
          :family_name_suffix_code => (name.family_name_suffix || '').soundex
      ) unless (name.voided? || name.person.nil?|| name.person.voided? || name.person.patient.nil?|| name.person.patient.voided?)
    }
  end

  def self.find_most_common(field_name, search_string)
    soundex = (search_string || '').soundex
    self.find_by_sql([
                         "SELECT DISTINCT #{field_name} AS #{field_name}, count(person_name.person_name_id) AS id
       FROM person_name_code \
       INNER JOIN person_name ON person_name_code.person_name_id = person_name.person_name_id \
       WHERE  person_name.voided = 0 AND #{field_name}_code LIKE ? \
       GROUP BY #{field_name} \
       ORDER BY \
        CASE INSTR(#{field_name},?) WHEN 0 THEN 9999 ELSE INSTR(#{field_name},?) END ASC \
       LIMIT 10",
                         "#{soundex}%", search_string, search_string])
  end

  def self.find_top_ten(field_name)
    self.find_by_sql([
                         "SELECT DISTINCT #{field_name} AS #{field_name}, count(person_name.person_name_id) AS id
       FROM person_name_code \
       INNER JOIN person_name ON person_name_code.person_name_id = person_name.person_name_id \
       INNER JOIN person ON person.person_id = person_name.person_id \
       WHERE person.voided = 0 AND person_name.voided = 0 \
       GROUP BY #{field_name} \
       ORDER BY \
                         #{field_name} ASC \
       LIMIT 10"])
  end
end
