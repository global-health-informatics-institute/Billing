class OrderPayment < ActiveRecord::Base

  #default_scope {-> { where "#{self.table_name}.voided = false" }}
  default_scope { where(voided: false) }
  belongs_to :order_entry, :foreign_key => :order_entry_id
  belongs_to :receipt, class_name: "Receipt",:foreign_key => :receipt_number
  has_one :patient, :through => :order_entry
  has_one :service, :through => :order_entry
  belongs_to :cashier, class_name: "User", :foreign_key => :cashier

  def clinic_type
    self.location == Location.find_by_name("General").id ? "general" : "private"
  end

  def service_category
    self.order_entry.service.service_type_id
  end

  def void(reason,user)
    OrderPayment.transaction do
      self.voided = true
      self.voided_by= user
      self.voided_reason= reason
      self.save
    end

  end
end
