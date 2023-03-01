class MedicalSchemeProvider < ActiveRecord::Base
  has_many :medical_schemes, :foreign_key => :medical_scheme_provider
  has_one :user, :foreign_key => :creator

  def schemes
    self.medical_schemes
  end

  def phone_numbers
    return ((self.phone_number_1 + self.phone_number_2).blank? ? "" : (self.phone_number_1.blank? ? self.phone_number_2 : (self.phone_number_2.blank? ? self.phone_number_1 : "#{self.phone_number_1} / #{self.phone_number_2}")))
  end
end
