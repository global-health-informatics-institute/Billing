module MainHelper
  def report_options
    options = %w[Daily Weekly Monthly Range]
    return options
  end

  def income_summary(data)
    records = []

    (data || []).each do |y|

      records << {receipt: y.receipt_number, received_by: y.cashier.name, paid: y.total(true),
                  bill: y.total_bill(true), voided: y.voided}
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
end
