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



  # cashier summary
  def total_summary(cashier_id:, start_date:, end_date:)
    total_full_price = OrderEntry.unscoped.where(cashier: cashier_id, created_at: start_date..end_date,).sum(:full_price)  
    total_amount_paid = OrderPayment.unscoped.where(cashier: cashier_id, created_at: start_date..end_date,).sum(:amount)
    total_voided_price = OrderEntry.unscoped.where(cashier: cashier_id, created_at: start_date..end_date, voided: 1).sum(:full_price)
    total_voided_paid = OrderPayment.unscoped.where(cashier: cashier_id, created_at: start_date..end_date, voided: 1).sum(:amount)
    total_refund= OrderPayment.unscoped.where(cashier: cashier_id, created_at: start_date..end_date, voided: 1, voided_reason: 'Refund').sum(:amount)
    return {
      total_full_price: total_full_price,
      total_amount_paid: total_amount_paid,
      total_voided_price: total_voided_price,
      total_voided_paid: total_voided_paid,
      total_refund: total_refund
    }
  end

  def service_totals(cashier_id:, start_date:, end_date:)
    # Define the service names and their corresponding keys
    service_keys = {
      'male adult' => :male_adult,
      'Female (non) antenatal' => :female_non_antenatal,
      'Child under 5' => :under_five,
      'Female antenatal' => :female_antenatal,
      'Kulera' => :kulera,
      'Scanning' => :scanning,
      'Ambulance' => :ambulance,
      'Ambulance (non-paying)' => :ambulance_non_paying
    }
  
    # Initialize result hash
    totals = {
      male_adult_price: 0, male_adult_paid: 0,
      female_non_antenatal_price: 0, female_non_antenatal_paid: 0,
      under_five_price: 0, under_five_paid: 0,
      female_antenatal_price: 0, female_antenatal_paid: 0,
      kulera_price: 0, kulera_paid: 0,
      scanning_price: 0, scanning_paid: 0,
      ambulance_price: 0, ambulance_paid: 0,
      ambulance_non_paying_price: 0, ambulance_non_paying_paid: 0
    }
  
    service_keys.each do |service_name, key|
      service_ids = Service.where(name: service_name).pluck(:service_id)
      order_entries = OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: service_ids)
      totals["#{key}_price".to_sym] = order_entries.sum(:full_price)
      totals["#{key}_paid".to_sym] = OrderPayment.where(order_entry_id: order_entries.pluck(:order_entry_id)).sum(:amount)
    end

    totals
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
  

  # income summary
  def income_summary_aggregate(range:)
    user_ids = User.joins(:user_roles)
                   .where(retired: false)
                   .where(user_roles: { role: ['General Registration Clerk', 'Registration Clerk'] })
                   .pluck(:user_id)
  
      user_ids.map do |uid|
        user = User.find(uid)
        income_totals = income_helper(cashier_id: uid, start_date: range.begin, end_date: range.end)
        income_service_total = income_service_totals(cashier_id: uid, start_date: range.begin, end_date: range.end)

          { 
            cashier_name: user.name,
            service_totals: income_service_total,
            totals: income_totals
          }
      end
  
  end

  def income_service_totals(cashier_id: , start_date: , end_date:)
    {
      service_name_1: 'Male adult',
      male_adult_price:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Male aldult').pluck(:service_id)
        ).sum(:full_price),
      male_adult_paid:
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Male aldult').pluck(:service_id)
        )
        .pluck(:order_entry_id)).sum(:amount),


      service_name_2: 'Female non antenatal',
      female_non_antenatal_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Female (non) antenatal').pluck(:service_id)
        ).sum(:full_price),
      female_non_antenatal_paid: 
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Female (non) antenatal').pluck(:service_id)
        )
        .pluck(:order_entry_id)).sum(:amount),
      
      service_name_3: 'Under 5',
      under_five_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Child under 5').pluck(:service_id)
        ).sum(:full_price),
      under_five_paid: 
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Child under 5').pluck(:service_id)
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_4: 'Female antenatal',
      female_antenatal_price:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Female antenatal').pluck(:service_id)
        ).sum(:full_price),
      female_antenatal_paid:  
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Female antenatal').pluck(:service_id)
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_5: 'Kulera',
      kulera_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Kulera').pluck(:service_id)
        ).sum(:full_price),
      kulera_paid:  
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Kulera').pluck(:service_id)
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_6: 'Scanning',
      scanning_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Scanning').pluck(:service_id)
        ).sum(:full_price),
      scanning_paid: 
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Scanning').pluck(:service_id)
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_7: 'Ambulance',
      ambulance_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Ambulance').pluck(:service_id)
        ).sum(:full_price),
      mbulance_paid: 
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Ambulance').pluck(:service_id)
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_8: 'Ambulance (non-paying)',
      ambulance_non_paying_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Ambulance (non-paying)').pluck(:service_id)
        ).sum(:full_price),
      ambulance_non_paying_paid:  
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        Service.where(name: 'Ambulance (non-paying)').pluck(:service_id)
        )
        .pluck(:order_entry_id)).sum(:amount),
    }
  end

  
  def income_helper(cashier_id:, start_date:, end_date:)
    total_full_price = OrderEntry.unscoped.where(cashier: cashier_id, created_at: start_date..end_date,).sum(:full_price)  
    total_amount_paid = OrderPayment.unscoped.where(cashier: cashier_id, created_at: start_date..end_date,).sum(:amount)
    total_voided_price = OrderEntry.unscoped.where(cashier: cashier_id, created_at: start_date..end_date, voided: 1).sum(:full_price)
    total_voided_paid = OrderPayment.unscoped.where(cashier: cashier_id, created_at: start_date..end_date, voided: 1).sum(:amount)
    total_refund= OrderPayment.unscoped.where(cashier: cashier_id, created_at: start_date..end_date, voided: 1, voided_reason: 'Refund').sum(:amount)
    return {
      total_full_price: total_full_price,
      total_amount_paid: total_amount_paid,
      total_voided_price: total_voided_price,
      total_voided_paid: total_voided_paid,
      total_refund: total_refund
    }
  end
  

  # income listing
  def income_listing(data)
    records = []

    (data || []).each do |y|

      records << {receipt: y.receipt_number, received_by: y.cashier.name, paid: y.total(true),
                  bill: y.total_bill(true), voided: y.voided}
    end
    return records
  end


  # cash listing
  def cashier_listing(data)
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
end


def find_user(uid)
  user = User.find_by(user_id: uid)
  if user
    person = user.person
    if person
      names = person.names
      if names.any?
        name = names.first
        return "#{name.given_name} #{name.family_name}"
      else
        return "un assigned"
      end
    else
      return "unassigned"
    end
  else
    return "unassigned"
  end
end
