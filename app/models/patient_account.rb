class PatientAccount < ActiveRecord::Base

  default_scope { order('patient_accounts.active_from DESC') }
  belongs_to :patient, :foreign_key => :patient_id
  has_one :medical_scheme, :foreign_key => :medical_scheme_id
  has_one :medical_scheme_provider, through: :medical_scheme
  has_one :user, :foreign_key => :creator

  #accessor methods
  def scheme_description
    return "#{self.medical_scheme_provider.company_name} (#{scheme_name})"
  end

  def scheme_name
    scheme = self.medical_scheme
    if scheme.blank?
      return 'General'
    else
      return scheme.name
    end
  end


end
