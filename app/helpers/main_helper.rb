module MainHelper
  def report_options
    options = %w[Daily Weekly Monthly Range]
    return options
  end

  def income_summary(data)
    records = []

    (data || []).each do |y|

      records << {
        receipt: y.receipt_number, received_by: y.cashier.name, paid: y.total(true),
        bill: y.total_bill(true), voided: y.voided
      }

              
    end
    return records
  end

  def cash_summary(data)
    totals = {private: 0, general: 0}
    records = Hash[*ServiceType.all.collect{|x| [x.id,{name: x.name, private: 0, general: 0}]}.flatten(1)]
    (data || []).each do |payment|
      entry = payment.order_entry
      next if entry.blank?
      records[entry.service.service_type_id][entry.clinic_type.to_sym] +=payment.amount
      totals[entry.clinic_type.to_sym] += payment.amount
    end
    return records,totals
  end

  def census(patients)

    result = {under_five: {M: 0, F: 0},under_twelve: {M: 0, F: 0}, adult: {M: 0, F: 0}}

    (patients || []).each do |patient|
      next if patient.blank?
      person = patient.person
      if person.is_child?
        age_in_days = (Date.current - person.birthdate).to_i rescue 0
        if age_in_days < 1825
          result[:under_five][person.gender.to_sym] += 1
        else
          result[:under_twelve][person.gender.to_sym] += 1
        end

      else
        result[:adult][person.gender.to_sym] += 1
      end
    end
    return result
  end

  def work_shifts
    return {"Day" => ['08:00:00', '16:29:59'], "Night" => ['16:30:00','07:59:59']}
  end




  def total_summary(cashier_id:, start_date:, end_date:)
    total_full_price = OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date).sum(:full_price)  
    total_amount_paid = OrderPayment.where(cashier: cashier_id, created_at: start_date..end_date, voided: 0).sum(:amount)
    total_voided = OrderEntry.unscoped.where(cashier: cashier_id, created_at: start_date..end_date, voided: 1).sum(:full_price)
    return {
      total_full_price: total_full_price,
      total_amount_paid: total_amount_paid,
      total_voided: total_voided
    }
  end


  def voided_summary(cashier_id:, start_date:, end_date:)
    voided_records = []
    
    voided_payments = OrderEntry.unscoped.where(cashier: cashier_id, created_at: start_date..end_date, voided: 1)
    
    voided_payments.each do |payment|
      receipt_number = OrderPayment.where(order_payment_id: payment.order_entry_id).pluck(:receipt_number).first || "No receipt"
      
      voided_records << {
        receipt: receipt_number,
        voided_at: payment.created_at,
        voided_reason: payment.voided_reason,
        voided_full_price: payment.full_price
      }
    end
  
    if voided_records.blank?
      return [{
        receipt: "No receipt",
        voided_at: '',
        voided_reason: "",
        voided_full_price: "00"
      }]
    end
  
    voided_records
  end
  


end
