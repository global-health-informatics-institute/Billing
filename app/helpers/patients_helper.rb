module PatientsHelper
  def patient_json(params,current_ta='Unknown',identifier=[],print_barcode=false)
    if params["age_estimate"].blank?

      year = params["birth_year"]
      month = params["birth_month"]
      day = params["birth_day"]

      month_i = (month || 0).to_i
      month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
      month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?

      if month_i == 0 || month == "Unknown"
        dob = Date.new(year.to_i,7,1)
        dob_estimate = true
      elsif day.blank? || day == "Unknown" || day == 0
        dob = Date.new(year.to_i,month_i,15)
        dob_estimate = true
      else
        dob = Date.new(year.to_i,month_i,day.to_i)
        dob_estimate = false
      end
    else
      dob_estimate = true
      yr = (Date.current.year - params["age_estimate"].to_i);

      dob =  "#{yr}-07-05";
    end

    json = {
      'national_id' => nil,
      'application' => "#{name_of_app}",
      'site_code' => "#{facility_code}",
      'return_path' => params[:return_path],
      'print_barcode' => print_barcode,
      'names' =>
        {
          'family_name' => params[:names][:family_name],
          'given_name' => params[:names][:given_name],
          'middle_name' => params[:names][:middle_name],
          'maiden_name' => (params[:names][:family_name2].blank? ? nil : params[:names][:family_name2]),
          'gender' => (params[:gender])
        },
      'gender' => params[:gender],
      'person_attributes' => {
        'country_of_residence' => nil,
        'citizenship' => params["citizenship"],
        'occupation' => params["occupation"],
        'home_phone_number' => params["home_phone_number"],
        'cell_phone_number' => params["cell_phone_number"],
        'office_phone_number' => params["office_phone_number"],
        'race' => params["race"]
      },
      'birthdate' => dob,
      'patient' => {
        'identifiers' => (identifier.blank? ? [] : [identifier])
      },
      'birthdate_estimated' => dob_estimate,
      'addresses' => {
        'current_residence' => (params["addresses"]["address1"] rescue nil),
        'current_village' => (params["addresses"]["city_village"] rescue nil),
        'current_ta' => current_ta,
        'current_district' => (params["addresses"]["state_province"] rescue nil),
        'home_village' => (params["addresses"]["neighborhood_cell"] rescue nil),
        'home_ta' => (params["addresses"]["county_district"] rescue nil),
        'home_district' => (params["addresses"]["address2"] rescue nil),
        'landmark' => (params["addresses"]["address1"] rescue nil)
      }
    }.to_json
  end

  def past_records(entries)
    records = {}
    (entries || []).each do |entry|
      status = entry.status
      date = entry.order_date.strftime("%d %b %Y")

      records[date] = {"summary" => {},"details" => [], "receipts" => []} if records[date].blank?
      records[date]["details"] << {service: entry.description, quantity: entry.quantity,
                                   price: entry.full_price, id: entry.id,
                                   status: status[:bill_status]}
      records[date]["receipts"] += entry.receipts
      (records[date]["summary"]["bill"].blank? ? records[date]["summary"]["bill"] = entry.full_price : records[date]["summary"]["bill"]+= entry.full_price)
      (records[date]["summary"]["paid"].blank? ? records[date]["summary"]["paid"] = status[:amount] : records[date]["summary"]["paid"]+= status[:amount])

    end

    return records
  end

  def today_records(receipts)
    records = {}
    (receipts || []).each do |receipt|

      records[receipt.receipt_number] = {"details" => []} if records[receipt.receipt_number].blank?
      (receipt.order_payments || []).each do |payment|
        entry = payment.order_entry
        next if entry.blank?
        records[receipt.receipt_number]["details"] << {service: entry.description, quantity: entry.quantity,
                                                       price: entry.full_price, id: entry.id,
                                                       amount_paid: payment.amount}
      end

    end

    return records
  end

  def unpaid_records(orders)

    @unpaid_orders = {}
    @total = 0
    @amount_due = 0

    (orders || []).each do |record|
      if @unpaid_orders[record.service_id].blank?
        @unpaid_orders[record.service_id] = {service_name: record.description, amount: record.full_price ,
                                             quantity: record.quantity, id: [record.order_entry_id] }
      else
        @unpaid_orders[record.service_id][:amount] += record.full_price
        @unpaid_orders[record.service_id][:quantity] += record.quantity
        @unpaid_orders[record.service_id][:id] << record.order_entry_id
      end
      @total += record.full_price
      @amount_due += (record.full_price - record.amount_paid)
      #@amount_due = @total
    end

    return [@unpaid_orders, @total, @amount_due]
  end

  def patient_list(data)
    results = []

    (data || []).each do |record|
      name = record.names.first
      address = record.addresses.last
      results << {
        "_id" => record.patient.national_id,
        "patient_id" => (record.person_id rescue nil),
        "names" =>
          {
            "family_name" => (name.family_name rescue nil),
            "given_name" => (name.given_name rescue nil),
            "middle_name" => (name.middle_name rescue nil),
            "maiden_name" => (name.family_name2 rescue nil)
          },
        "gender" => (record.gender rescue nil),
        "person_attributes" => {
          "occupation" => (record.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Occupation").id).value rescue nil),
          "cell_phone_number" => (record.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Cell Phone Number").id).value rescue nil),
          "home_phone_number" => (record.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Home Phone Number").id).value rescue nil),
          "office_phone_number" => (record.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Office Phone Number").id).value rescue nil),
          "race" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Race").id).value rescue nil),
          "country_of_residence" => (record.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Country of Residence").id).value rescue nil),
          "citizenship" => (record.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Citizenship").id).value rescue nil)
        },
        "birthdate" => (record.birthdate rescue nil),
        "patient" => {
          "identifiers" => (record.patient.patient_identifiers.collect { |id| {id.type.name => id.identifier} if id.type.name.downcase != "national id" }.delete_if { |x| x.nil? } rescue [])
        },
        "birthdate_estimated" => ((record.birthdate_estimated rescue 0).to_s.strip == '1' ? true : false),
        "addresses" => {
          "current_residence" => (address.address1 rescue nil),
          "current_village" => (address.city_village rescue nil),
          "current_ta" => (address.township_division rescue nil),
          "current_district" => (address.state_province rescue nil),
          "home_village" => (address.neighborhood_cell rescue nil),
          "home_ta" => (address.county_district rescue nil),
          "home_district" => (address.address2 rescue nil)
        }
      }.to_json

    end
    return results
  end
end
