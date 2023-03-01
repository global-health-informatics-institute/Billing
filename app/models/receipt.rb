class Receipt < ActiveRecord::Base

  default_scope { where(voided: false) }
  self.primary_key = :receipt_number
  has_many :order_payments, :foreign_key => :receipt_number
  belongs_to :cashier, class_name: "User", :foreign_key => :cashier
  belongs_to :patient, :foreign_key => :patient_id

  validates_uniqueness_of :receipt_number
  before_create :complete_record

  def total(include_voided=false)

    if include_voided
      output = OrderPayment.find_by_sql("SELECT SUM(amount) as amount FROM order_payments where receipt_number='#{self.receipt_number}'").first.amount rescue 0
    else
      output = self.order_payments.select("SUM(amount) as amount").first.amount rescue 0
    end
   return output
  end

  def total_bill(include_voided=false)

    total = 0
    if include_voided
      total = OrderEntry.find_by_sql("SELECT SUM(full_price) as full_price FROM order_entries where
                                          order_entry_id in (SELECT order_entry_id FROM order_payments
                                          where receipt_number='#{self.receipt_number}')").first.full_price rescue 0
    else
      payments = self.order_payments.select(:order_entry_id)
      (payments || []).each do |payment|
        total += payment.order_entry.full_price
      end
    end

    return total
  end

  def complete_record
    self.payment_stamp= DateTime.current if self.payment_stamp.blank?
    self.receipt_number = next_number() if self.receipt_number.blank?
  end

  def next_number
    last_number = Receipt.find_by_sql("SELECT count(receipt_number) as count FROM receipts WHERE payment_stamp BETWEEN
                                     '#{Date.current.beginning_of_year.strftime('%Y-%m-%d 00:00:00')}' AND '#{DateTime.current.end_of_year}'").first
    new_number =  "#{(last_number.count.to_i + 1).to_s.rjust(6, '0')}-#{Date.current.strftime('%y')}"
    return new_number
  end

end
