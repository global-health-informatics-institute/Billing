class Patient < ActiveRecord::Base
  #establish_connection Registration
  self.table_name = "patient"
  include Openmrs

  before_create :before_create
  before_update :before_save
  before_save :before_save

  has_one :person, -> { where "voided = 0" }, :foreign_key => :person_id
  has_many :patient_identifiers,-> { where "voided = 0" }, :foreign_key => :patient_id, :dependent => :destroy
  has_many :names,-> { where "voided = false"}, :class_name => 'PersonName', :foreign_key => :person_id, :dependent => :destroy
  has_many :addresses,-> { where "voided = false" }, :class_name => 'PersonAddress', :foreign_key => :person_id, :dependent => :destroy
  has_many :person_attributes,-> { where "voided = 0" }, :class_name => 'PersonAttribute', :foreign_key => :person_id
  has_many :patient_accounts,-> { where "active = true" }, :foreign_key => :patient_id
  has_many :deposits,-> { where "voided = false" }, :foreign_key => :patient_id

  #Accessor methods. These methods are used to access values of various attributes
  def full_name
    names = self.names.first
    return (names.given_name || '') + " " + (names.family_name || '')
  end

  def sex
    self.person.gender == 'F' ? 'Female' : 'Male'
  end

  def gender
    self.person.gender
  end

  def current_district
    self.person.addresses.first.state_province rescue ""
  end

  def current_residence
    self.person.addresses.first.city_village rescue ""
  end

  def current_address
    address = self.current_district rescue ""
    if address.blank?
      address = self.current_residence rescue ""
    else
      address += ", " + self.current_residence unless self.current_residence.blank?
    end
    return address
  end

  def presentable_dob
      self.person.birthdate.strftime('%d/%b/%Y')
  end

  def dob
    self.person.birthdate.strftime('%Y-%m-%d')
  end

  def national_id
    self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
  end

  def health_insurance
    account = self.patient_accounts.first rescue nil
    if account.blank?
      return "None"
    else
      account.scheme_description
    end
  end

  def scheme_num
    return self.patient_accounts.first.scheme_number rescue ''
  end

  def amount_deposited
    amount = Deposit.select("SUM(amount_available) as amount_available").where(patient_id: self.id).first.amount_available rescue 0
    return (amount.blank? ? 0 : amount)
  end

  #Model functional methods. These functions are used to process various things related to the patient

  def after_void(reason = nil)
    self.patient.void(reason) rescue nil
    self.names.each{|row| row.void(reason) }
    self.addresses.each{|row| row.void(reason) }
    self.person_attributes.each{|row| row.void(reason) }
  end

  def self.search_locally(id)

    patient = PatientIdentifier.find_by_identifier(id).patient rescue nil

    national_id = ((patient.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil) || id)

    name = patient.person.names.last rescue nil

    address = patient.person.addresses.last rescue nil

    person = {
        "national_id" => national_id,
        "patient_id" => (patient.patient_id rescue nil),
        "application" => "Billing",
        "site_code" => "DLH",
        "names" =>
            {
                "family_name" => (name.family_name rescue nil),
                "given_name" => (name.given_name rescue nil),
                "middle_name" => (name.middle_name rescue nil),
                "maiden_name" => (name.family_name2 rescue nil)
            },
        "gender" => (patient.person.gender rescue nil),
        "person_attributes" => {
            "occupation" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Occupation").id).value rescue nil),
            "cell_phone_number" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Cell Phone Number").id).value rescue nil),
            "home_phone_number" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Home Phone Number").id).value rescue nil),
            "office_phone_number" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Office Phone Number").id).value rescue nil),
            "race" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Race").id).value rescue nil),
            "country_of_residence" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Country of Residence").id).value rescue nil),
            "citizenship" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Citizenship").id).value rescue nil)
        },
        "birthdate" => (patient.person.birthdate.strftime('%Y/%m/%d') rescue nil),
        "patient" => {
            "identifiers" => (patient.patient_identifiers.collect { |id| {id.type.name => id.identifier} if id.type.name.downcase != "national id" }.delete_if { |x| x.nil? } rescue [])
        },
        "birthdate_estimated" => ((patient.person.birthdate_estimated rescue 0).to_s.strip == '1' ? true : false),
        "addresses" => {
            "current_residence" => (address.address1 rescue nil),
            "current_village" => (address.city_village rescue nil),
            "current_ta" => (address.township_division rescue nil),
            "current_district" => (address.state_province rescue nil),
            "home_village" => (address.neighborhood_cell rescue nil),
            "home_ta" => (address.county_district rescue nil),
            "home_district" => (address.address2 rescue nil)
        }
    }

    return person
  end

  def create_national_id
    health_center_id = Location.current_health_center.location_id
    national_id_version = "1"
    national_id_prefix = "P#{national_id_version}#{health_center_id.to_s.rjust(3,"0")}"

    identifier_type = PatientIdentifierType.find_by_name("National ID")
    last_national_id = PatientIdentifier.where("identifier_type = ? AND left(identifier,5)= ?", identifier_type.id, national_id_prefix).order("identifier desc").first
    last_national_id_number = last_national_id.identifier rescue "0"

    next_number = (last_national_id_number[5..-2].to_i+1).to_s.rjust(7,"0")
    new_national_id_no_check_digit = "#{national_id_prefix}#{next_number}"
    check_digit = PatientIdentifier.calculate_checkdigit(new_national_id_no_check_digit[1..-1])
    new_national_id = "#{new_national_id_no_check_digit}#{check_digit}"
    patient_identifier = PatientIdentifier.new
    patient_identifier.type = identifier_type
    patient_identifier.identifier = new_national_id
    patient_identifier.patient = self
    patient_identifier.save
  end
end
