class Deposit < ActiveRecord::Base
  #default_scope {-> { where "#{self.table_name}.voided = false" }}
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :creator, class_name: 'User', :foreign_key => :creator

  def receipt_number
    "#{(self.id).to_s.rjust(6, '0')}"
  end
end
