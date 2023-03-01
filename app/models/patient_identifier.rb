class PatientIdentifier < ActiveRecord::Base
  #establish_connection Registration
  self.table_name= "patient_identifier"
  include Openmrs

  belongs_to :type,-> { where "retired = 0" }, :class_name => "PatientIdentifierType", :foreign_key => :identifier_type
  belongs_to :patient, -> { where "voided = 0" }

  before_create :before_create
  before_update :before_save
  before_save :before_save

  def self.calculate_checkdigit(number)
    # This is Luhn's algorithm for checksums
    # http://en.wikipedia.org/wiki/Luhn_algorithm
    # Same algorithm used by PIH (except they allow characters)
    number = number.to_s
    number = number.split(//).collect { |digit| digit.to_i }
    parity = number.length % 2

    sum = 0
    number.each_with_index do |digit,index|
      luhn_transform = ((index + 1) % 2 == parity ? (digit * 2) : digit)
      luhn_transform = luhn_transform - 9 if luhn_transform > 9
      sum += luhn_transform
    end

    checkdigit = (sum * 9 )%10
    return checkdigit

  end

  def self.identifier(patient_id, patient_identifier_type_id)
    patient_identifier = self.first.select("identifier").where("patient_id = ? and identifier_type = ?",patient_id, patient_identifier_type_id)

    return patient_identifier
  end

  def before_save
    self.creator = 1 if self.creator.blank?
    self.date_created = Time.now if self.date_created.blank?
  end

end
