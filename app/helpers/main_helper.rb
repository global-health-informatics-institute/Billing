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
      service_ids = service_ids_for_name(service_name)
      order_entries = OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: service_ids)
      totals["#{key}_price".to_sym] = order_entries.sum(:full_price)
      totals["#{key}_paid".to_sym] = OrderPayment.where(order_entry_id: order_entries.pluck(:order_entry_id)).sum(:amount)
    end

    totals
  end

  def service_ids_for_name(name)
    set_name = name.downcase.gsub(' ', '_').gsub(/[()]/, '')
    service_set = ServiceSet.find_by(name: set_name)
    if service_set
      service_set.services.pluck(:service_id)
    else
      Service.where(name: name).pluck(:service_id)
    end
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
        service_ids_for_name('Male adult')
        ).sum(:full_price),
      male_adult_paid:
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Male adult')
        )
        .pluck(:order_entry_id)).sum(:amount),


      service_name_2: 'Female non antenatal',
      female_non_antenatal_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Female (non) antenatal')
        ).sum(:full_price),
      female_non_antenatal_paid: 
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Female (non) antenatal')
        )
        .pluck(:order_entry_id)).sum(:amount),
      
      service_name_3: 'Under 5',
      under_five_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Child under 5')
        ).sum(:full_price),
      under_five_paid: 
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Child under 5')
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_4: 'Female antenatal',
      female_antenatal_price:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Female antenatal')
        ).sum(:full_price),
      female_antenatal_paid:  
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Female antenatal')
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_5: 'Kulera',
      kulera_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Kulera')
        ).sum(:full_price),
      kulera_paid:  
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Kulera')
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_6: 'Scanning',
      scanning_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Scanning')
        ).sum(:full_price),
      scanning_paid: 
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Scanning')
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_7: 'Ambulance',
      ambulance_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Ambulance')
        ).sum(:full_price),
      mbulance_paid: 
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Ambulance')
        )
        .pluck(:order_entry_id)).sum(:amount),

      service_name_8: 'Ambulance (non-paying)',
      ambulance_non_paying_price: 
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Ambulance (non-paying)')
        ).sum(:full_price),
      ambulance_non_paying_paid:  
        OrderPayment.where(order_entry_id:
        OrderEntry.where(cashier: cashier_id, created_at: start_date..end_date, service_id: 
        service_ids_for_name('Ambulance (non-paying)')
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

  # void listing
  def void_listing_helper(range:)
    records = []
    
    receipts = Receipt.unscoped.where(voided: 1, created_at: range)
    receipt_count = receipts.count
  
    receipts.find_each do |receipt|
      receipt_number = receipt.receipt_number
  
      # Calculate amount_billed by summing full_price from order_entries
      # that are related to order_payments for this receipt.
      sql_billed = <<-SQL
        SELECT SUM(full_price) AS full_price
        FROM order_entries
        WHERE order_entry_id IN (
          SELECT order_entry_id FROM order_payments WHERE receipt_number = '#{receipt_number}'
        )
      SQL
  
      result = OrderEntry.find_by_sql(sql_billed.strip).first
      amount_billed = result&.full_price || 0
  
      # Calculate amount_paid by summing the amount from matching OrderPayments.
      amount_paid = OrderPayment.unscoped.where(receipt_number: receipt_number).sum(:amount)
  
      # Retrieve voided_reason from order_entries associated with this receipt via order_payments.
      sql_voided_reason = <<-SQL
        SELECT voided_reason
        FROM order_entries
        WHERE order_entry_id IN (
          SELECT order_entry_id FROM order_payments WHERE receipt_number = '#{receipt_number}'
        )
      SQL
  
      voided_reason_record = OrderEntry.find_by_sql(sql_voided_reason.strip).last
      voided_reason = voided_reason_record&.voided_reason || 'Other'
  
      records << {
        receipt_number: receipt_number,
        amount_billed: amount_billed,
        amount_paid: amount_paid,
        issued_time: receipt.created_at,
        voided_time: receipt.updated_at,
        voided_reason: voided_reason
      }
    end
  
    {
      receipt_count: receipt_count,
      records: records
    }
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

