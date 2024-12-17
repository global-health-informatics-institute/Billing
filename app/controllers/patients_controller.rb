class PatientsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:confirm_demographics]

  def create
    raise params.inspect
  end

  def confirm_demographics

    @settings = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env] rescue {}
    @use_dde = YAML.load_file("#{Rails.root}/config/application.yml")['create_from_dde'] rescue false

    json_params = view_context.patient_json(params[:person],params["CURRENT AREA OR T/A"],params["identifier"],true)

    @json = JSON.parse(json_params)

    if !@settings.blank? && @use_dde
      #DDE available

      @settings = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env] # rescue {}

      if secure?
        url = "https://#{(@settings["dde_username"])}:#{(@settings["dde_password"])}@#{(@settings["dde_server"])}/ajax_process_data"
      else
        url = "http://#{(@settings["dde_username"])}:#{(@settings["dde_password"])}@#{(@settings["dde_server"])}/ajax_process_data"
      end

      @results = RestClient.post(url, {"person" => json_params})

    else
      #No dde setting therefore create locally

      @results = Person.joins(:names).where(person_name: {given_name: @json["names"]["given_name"],
                                                          family_name: @json["names"]["family_name"]},
                                            gender: @json["names"]["gender"])


      if @results.blank?
        matching_people = @results.collect{| person |
          person.person_id
        }

        # raise matching_people.to_yaml

        people_like = Person.joins(:names =>[:person_name_code]).where(person_name_code: {given_name_code: @json["names"]["given_name"].soundex, family_name_code: @json["names"]["family_name"].soundex}, gender: @json["names"]["gender"]).where.not(person_id: matching_people).order("person_name.given_name ASC, person_name_code.family_name_code ASC")
        @results = @results + people_like
      end
    end
    render :layout => 'touch'
  end

  def new
    
    
    settings = YAML.load_file("#{Rails.root}/config/globals.yml")[Rails.env] rescue {}

    @show_middle_name = (settings["show_middle_name"] == true ? true : false) rescue false

    @show_maiden_name = (settings["show_maiden_name"] == true ? true : false) rescue false

    @show_birthyear = (settings["show_birthyear"] == true ? true : false) rescue false

    @show_birthmonth = (settings["show_birthmonth"] == true ? true : false) rescue false

    @show_birthdate = (settings["show_birthdate"] == true ? true : false) rescue false

    @show_age = (settings["show_age"] == true ? true : false) rescue false

    @show_region_of_origin = (settings["show_region_of_origin"] == true ? true : false) rescue false

    @show_district_of_origin = (settings["show_district_of_origin"] == true ? true : false) rescue false

    @show_t_a_of_origin = (settings["show_t_a_of_origin"] == true ? true : false) rescue false

    @show_home_village = (settings["show_home_village"] == true ? true : false) rescue false

    @show_current_region = (settings["show_current_region"] == true ? true : false) rescue false

    @show_current_district = (settings["show_current_district"] == true ? true : false) rescue false

    @show_current_t_a = (settings["show_current_t_a"] == true ? true : false) rescue false

    @show_current_village = (settings["show_current_village"] == true ? true : false) rescue false

    @show_current_landmark = (settings["show_current_landmark"] == true ? true : false) rescue false

    @show_cell_phone_number = (settings["show_cell_phone_number"] == true ? true : false) rescue false

    @show_office_phone_number = (settings["show_office_phone_number"] == true ? true : false) rescue false

    @show_home_phone_number = (settings["show_home_phone_number"] == true ? true : false) rescue false

    @show_occupation = (settings["show_occupation"] == true ? true : false) rescue false

    @show_nationality = (settings["show_nationality"] == true ? true : false) rescue false

    @occupations = ['','Driver','Housewife','Messenger','Business','Farmer','Salesperson','Teacher',
                    'Student','Security guard','Domestic worker', 'Police','Office worker',
                    'Preschool child','Mechanic','Prisoner','Craftsman','Healthcare Worker','Soldier'].sort.concat(["Other","Unknown"])

    @destination = request.referrer

    render :layout => 'touch'
  end

  def search
    @settings = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env] rescue {}

    @globals = YAML.load_file("#{Rails.root}/config/globals.yml")[Rails.env] rescue {}

    render :layout => 'touch'
  end

  def ajax_search
    pagesize = 3

    page = (params[:page] || 1)

    offset = ((page.to_i - 1) * pagesize)

    offset = 0 if offset < 0

    result = []

    filter = {}

    settings = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env] # rescue {}
    use_dde = YAML.load_file("#{Rails.root}/config/application.yml")['create_from_dde'] rescue false
    if !settings.blank? && use_dde
      search_hash = {
        "names" => {
          "given_name" => (params["given_name"] rescue nil),
          "family_name" => (params["family_name"] rescue nil)
        },
        "gender" => params["gender"]
      }

      if !search_hash["names"]["given_name"].blank? and !search_hash["names"]["family_name"].blank? and !search_hash["gender"].blank? # and result.length < pagesize

        pagesize += pagesize - result.length
        if secure?
          url = "https://#{settings["dde_username"]}:#{settings["dde_password"]}@#{settings["dde_server"]}/ajax_process_data"
        else
          url = "http://#{settings["dde_username"]}:#{settings["dde_password"]}@#{settings["dde_server"]}/ajax_process_data"
        end
        remote = RestClient.post(url, {:person => search_hash, :page => page, :pagesize => pagesize}, {:accept => :json})

        json = JSON.parse(remote)

        json.each do |person|

          entry = JSON.parse(person)

          entry["application"] = "#{name_of_app}"
          entry["site_code"] = "#{facility_code}"

          entry["national_id"] = entry["_id"] if entry["national_id"].blank? and !entry["_id"].blank?

          filter[entry["national_id"]] = true
          (entry["patient"]["identifiers"] || []).each do |identifiers|
            filter[identifiers["Old Identification Number"]] = true if !identifiers["Old Identification Number"].blank?
          end

          entry["age"] = (((Date.today - entry["birthdate"].to_date).to_i / 365) rescue nil)

          entry.delete("created_at") rescue nil
          entry.delete("patient_assigned") rescue nil
          entry.delete("assigned_site") rescue nil
          entry["names"].delete("family_name_code") rescue nil
          entry["names"].delete("given_name_code") rescue nil
          entry.delete("_id") rescue nil
          entry.delete("updated_at") rescue nil
          entry.delete("old_identification_number") rescue nil
          entry.delete("type") rescue nil
          entry.delete("_rev") rescue nil

          result << entry

        end
      end
    end

    # pagesize = ((pagesize) * 2) - result.length

    Person.all.joins(:names).where("given_name = ? AND family_name = ? AND gender = ?", params["given_name"], params["family_name"], params["gender"]).limit(pagesize).offset(offset).each do |person|

      patient = person.patient # rescue nil

      national_id = (patient.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil)

      next if filter[national_id]

      name = patient.person.names.last rescue nil

      address = patient.person.addresses.last rescue nil

      person = {
        "local" => true,
        "national_id" => national_id,
        "patient_id" => (patient.patient_id rescue nil),
        "age" => (((Date.today - patient.person.birthdate.to_date).to_i / 365) rescue nil),
        "names" =>
          {
            "family_name" => (name.family_name rescue nil),
            "given_name" => (name.given_name rescue nil),
            "middle_name" => (name.middle_name rescue nil),
            "maiden_name" => (name.family_name2 rescue nil)
          },
        "gender" => (patient.person.gender rescue nil),
        "person_attributes" => {
          "occupation" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Occupation").id).value rescue nil),
          "cell_phone_number" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Cell Phone Number").id).value rescue nil),
          "home_phone_number" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Home Phone Number").id).value rescue nil),
          "office_phone_number" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Office Phone Number").id).value rescue nil),
          "race" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Race").id).value rescue nil),
          "country_of_residence" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Country of Residence").id).value rescue nil),
          "citizenship" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Citizenship").id).value rescue nil)
        },
        "birthdate" => (patient.person.birthdate rescue nil),
        "patient" => {
          "identifiers" => (patient.patient_identifiers.collect { |id| {id.type.name => id.identifier} if id.type.name.downcase != "national id" }.delete_if { |x| x.nil? } rescue [])
        },
        "birthdate_estimated" => ((patient.person.birthdate_estimated rescue 0).to_s.strip == '1' ? true : false),
        "addresses" => {
          "current_residence" => (address.address1 rescue nil),
          "current_village" => (address.city_village rescue nil),
          "current_ta" => (address.township_division rescue nil),
          "current_district" => (address.state_province rescue nil),
          "home_village" => (address.neighborhood_cell rescue nil),
          "home_ta" => (address.county_district rescue nil),
          "home_district" => (address.address2 rescue nil)
        }
      }

      person["application"] = "#{name_of_app}"
      person["site_code"] = "#{facility_code}"

      result << person

      # TODO: Need to find a way to limit in a better way the number of records returned without skipping any as some will never be seen with the current approach

      # break if result.length >= 7

    end if pagesize > 0 and result.length < 8

    render :text => result.to_json

  end

  def patient_demographics
    settings = YAML.load_file("#{Rails.root}/config/globals.yml")[Rails.env] rescue {}

    @show_middle_name = (settings["show_middle_name"] == true ? true : false) rescue false

    @show_maiden_name = (settings["show_maiden_name"] == true ? true : false) rescue false

    @show_nationality = (settings["show_nationality"] == true ? true : false) rescue false

    @show_region_of_origin = (settings["show_region_of_origin"] == true ? true : false) rescue false

    @show_current_district = (settings["show_current_district"] == true ? true : false) rescue false

    @show_cell_phone_number = (settings["show_cell_phone_number"] == true ? true : false) rescue false

    @show_office_phone_number = (settings["show_office_phone_number"] == true ? true : false) rescue false

    @show_home_phone_number = (settings["show_home_phone_number"] == true ? true : false) rescue false

    @show_occupation = (settings["show_occupation"] == true ? true : false) rescue false

    @person = Patient.find(params[:id]).person
  end

  def edit
    @field = params[:field]

    if params[:id].blank?
      person_id = params[:patient_id]
    else
      person_id = params[:id]
    end
    @person = Person.find(person_id)

    @patient = @person.patient rescue nil

    render :layout => 'touch'
  end

  def update

    @settings = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env] rescue {}
    use_dde = YAML.load_file("#{Rails.root}/config/application.yml")['create_from_dde'] rescue false

    person = Person.find(params[:person_id])
    patient = person.patient rescue nil

    if patient.blank?

      flash[:error] = "Sorry, patient with that ID not found! Update failed."

      redirect_to "/" and return

    end

    if !@settings.blank? && use_dde

      national_id = ((patient.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil) || params[:id])

      name = patient.person.names.last rescue nil

      address = patient.person.addresses.last rescue nil

      dob = (patient.person.birthdate.strftime("%Y-%m-%d") rescue nil)

      estimate = false

      if !(params[:person][:birth_month] rescue nil).blank? and (params[:person][:birth_month] rescue nil).to_s.downcase == "unknown"

        dob = "#{params[:person][:birth_year]}-07-10"

        estimate = true

      elsif !(params[:person][:birth_month] rescue nil).blank? and (params[:person][:birth_month] rescue nil).to_s.downcase != "unknown" and !(params[:person][:birth_day] rescue nil).blank? and (params[:person][:birth_day] rescue nil).to_s.downcase == "unknown"

        dob = "#{params[:person][:birth_year]}-#{"%02d" % params[:person][:birth_month].to_i}-05"

        estimate = true

      elsif !(params[:person][:birth_month] rescue nil).blank? and (params[:person][:birth_month] rescue nil).to_s.downcase != "unknown" and !(params[:person][:birth_day] rescue nil).blank? and (params[:person][:birth_day] rescue nil).to_s.downcase != "unknown" and !(params[:person][:birth_year] rescue nil).blank? and (params[:person][:birth_year] rescue nil).to_s.downcase != "unknown"

        dob = "#{params[:person][:birth_year]}-#{"%02d" % params[:person][:birth_month].to_i}-#{"%02d" % params[:person][:birth_day].to_i}"

        estimate = false

      end

      if (params[:person][:attributes]["citizenship"] == "Other" rescue false)

        params[:person][:attributes]["citizenship"] = params[:person][:attributes]["race"]
      end

      identifiers = []

      patient.patient_identifiers.each { |id|
        identifiers << {id.type.name => id.identifier} if id.type.name.downcase != "national id"
      }

      # raise identifiers.inspect

      person = {
        "national_id" => national_id,
        "application" => "#{@settings["application_name"]}",
        "site_code" => "#{@settings["site_code"]}",
        "return_path" => "http://#{request.host_with_port}/process_result",
        "patient_id" => (patient.patient_id rescue nil),
        "patient_update" => true,
        "names" =>
          {
            "family_name" => (!(params[:person][:names][:family_name] rescue nil).blank? ? (params[:person][:names][:family_name] rescue nil) : (name.family_name rescue nil)),
            "given_name" => (!(params[:person][:names][:given_name] rescue nil).blank? ? (params[:person][:names][:given_name] rescue nil) : (name.given_name rescue nil)),
            "middle_name" => (!(params[:person][:names][:middle_name] rescue nil).blank? ? (params[:person][:names][:middle_name] rescue nil) : (name.middle_name rescue nil)),
            "maiden_name" => (!(params[:person][:names][:family_name2] rescue nil).blank? ? (params[:person][:names][:family_name2] rescue nil) : (name.family_name2 rescue nil))
          },
        "gender" => (!params["gender"].blank? ? params["gender"] : (patient.person.gender rescue nil)),
        "person_attributes" => {
          "occupation" => (!(params[:person][:attributes][:occupation] rescue nil).blank? ? (params[:person][:attributes][:occupation] rescue nil) :
                             (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Occupation").id).value rescue nil)),

          "cell_phone_number" => (!(params[:person][:attributes][:cell_phone_number] rescue nil).blank? ? (params[:person][:attributes][:cell_phone_number] rescue nil) :
                                    (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Cell Phone Number").id).value rescue nil)),

          "home_phone_number" => (!(params[:person][:attributes][:home_phone_number] rescue nil).blank? ? (params[:person][:attributes][:home_phone_number] rescue nil) :
                                    (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Home Phone Number").id).value rescue nil)),

          "office_phone_number" => (!(params[:person][:attributes][:office_phone_number] rescue nil).blank? ? (params[:person][:attributes][:office_phone_number] rescue nil) :
                                      (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Office Phone Number").id).value rescue nil)),

          "country_of_residence" => (!(params[:person][:attributes][:country_of_residence] rescue nil).blank? ? (params[:person][:attributes][:country_of_residence] rescue nil) :
                                       (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Country of Residence").id).value rescue nil)),

          "citizenship" => (!(params[:person][:attributes][:citizenship] rescue nil).blank? ? (params[:person][:attributes][:citizenship] rescue nil) :
                              (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Citizenship").id).value rescue nil))
        },
        "birthdate" => dob,
        "patient" => {
          "identifiers" => identifiers
        },
        "birthdate_estimated" => estimate,
        "addresses" => {
          "current_residence" => (!(params[:person][:attributes][:country_of_residence] rescue nil).blank? ? (params[:person][:addresses][:address1] rescue nil) : (address.address1 rescue nil)),
          "current_village" => (!(params[:person][:attributes][:country_of_residence] rescue nil).blank? ? (params[:person][:addresses][:city_village] rescue nil) : (address.city_village rescue nil)),
          "current_ta" => (!(params[:person][:attributes][:country_of_residence] rescue nil).blank? ? (params[:person][:addresses][:township_division] rescue nil) : (address.township_division rescue nil)),
          "current_district" => (!(params[:person][:attributes][:country_of_residence] rescue nil).blank? ? (params[:person][:addresses][:state_province] rescue nil) : (address.state_province rescue nil)),
          "home_village" => (!(params[:person][:attributes][:citizenship] rescue nil).blank? ? (params[:person][:addresses][:neighborhood_cell] rescue nil) : (address.neighborhood_cell rescue nil)),
          "home_ta" => (!(params[:person][:attributes][:citizenship] rescue nil).blank? ? (params[:person][:addresses][:county_district] rescue nil) : (address.county_district rescue nil)),
          "home_district" => (!(params[:person][:attributes][:citizenship] rescue nil).blank? ? (params[:person][:addresses][:address2] rescue nil) : (address.address2 rescue nil))
        }
      }

      if secure?
        url = "https://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/process_confirmation"
      else
        url = "http://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/process_confirmation"
      end
      result = RestClient.post(url, {:person => person, :target => "update"})

      json = JSON.parse(result) rescue {}

      if (json["patient"]["identifiers"] rescue "").class.to_s.downcase == "hash"

        tmp = json["patient"]["identifiers"]

        json["patient"]["identifiers"] = []

        tmp.each do |key, value|

          json["patient"]["identifiers"] << {key => value}

        end

      end

      patient_id = DDE.search_and_or_create(json.to_json) # rescue nil

      # raise patient_id.inspect

      patient = Patient.find(patient_id) rescue nil

      print_and_redirect("/patients/national_id_label?patient_id=#{patient_id}", "/patients/patient_demographics/id=#{patient_id}") and return if !patient.blank? and (json["print_barcode"] rescue false)

    else

      print_barcode = false

      case params[:update_field]
      when 'given_name'
        # raise params.inspect
        person.names.first.update("given_name" => params[:person][:names]["given_name"])
        print_barcode = true
      when 'middle_name'
        person.names.first.update("middle_name" => params[:person][:names]["middle_name"])
        print_barcode = true
      when 'family_name'
        person.names.first.update("family_name" => params[:person][:names]["family_name"])
        print_barcode = true
      when 'maiden_name'
        person.names.first.update("family_name2" => params[:person][:names]["maiden_name"])
        print_barcode = true
      when 'gender'
        person.gender = params["gender"]
        person.save
        print_barcode = true

      when 'birthdate'
        estimate = false
        dob = ""

        if !(params[:person][:birth_month] rescue nil).blank? and (params[:person][:birth_month] rescue nil).to_s.downcase == "unknown"

          dob = "#{params[:person][:birth_year]}-07-10"

          estimate = true
        elsif (params[:person][:birth_month] rescue nil).blank? and !(params[:person][:age_estimate] rescue nil).blank?
          year = Date.current.year - params[:person][:age_estimate].to_i
          dob = "#{year}-07-10"
        elsif !(params[:person][:birth_month] rescue nil).blank? and (params[:person][:birth_month] rescue nil).to_s.downcase != "unknown" and !(params[:person][:birth_day] rescue nil).blank? and (params[:person][:birth_day] rescue nil).to_s.downcase == "unknown"

          dob = "#{params[:person][:birth_year]}-#{"%02d" % params[:person][:birth_month].to_i}-05"

          estimate = true

        elsif !(params[:person][:birth_month] rescue nil).blank? and (params[:person][:birth_month] rescue nil).to_s.downcase != "unknown" and !(params[:person][:birth_day] rescue nil).blank? and (params[:person][:birth_day] rescue nil).to_s.downcase != "unknown" and !(params[:person][:birth_year] rescue nil).blank? and (params[:person][:birth_year] rescue nil).to_s.downcase != "unknown"

          dob = "#{params[:person][:birth_year]}-#{"%02d" % params[:person][:birth_month].to_i}-#{"%02d" % params[:person][:birth_day].to_i}"

          estimate = false

        end

        person.birthdate =  dob
        person.birthdate_estimated =  estimate
        person.save
        print_barcode = true

      # when 'state_province'
      #   #current residence
      #
      #   address = PersonAddress.where(person_id: person.id).first_or_initialize
      #   address.state_province = params[:person][:addresses][:state_province]
      #   address.township_division = params[:person][:addresses][:township_division]
      #   address.city_village = params[:person][:addresses][:city_village]
      #   address.address1 = params[:person][:addresses][:address1]
      #   address.save
      #   print_barcode = true

      when 'address2'
        #home district
        address = PersonAddress.where(person_id: person.id).first_or_initialize
        address.address2 = params[:person][:addresses][:address2]
        address.county_district = params[:person][:addresses][:county_district]
        address.city_village = params[:person][:addresses][:city_village]
        address.save

      when 'cell_phone_number'
        attrib_type = PersonAttributeType.find_by_name("Cell Phone Number").id
        person_attrib = PersonAttribute.where(person_id: person.person_id, person_attribute_type_id: attrib_type).first_or_initialize
        person_attrib.value = params[:person][:attributes][:cell_phone_number]
        person_attrib.save
      when 'home_phone_number'
        attrib_type = PersonAttributeType.find_by_name("Home Phone Number").id
        person_attrib = PersonAttribute.where(person_id: person.person_id, person_attribute_type_id: attrib_type).first_or_initialize
        person_attrib.value = params[:person][:attributes][:home_phone_number]
        person_attrib.save
      when 'office_phone_number'
        attrib_type = PersonAttributeType.find_by_name("Office Phone Number").id
        person_attrib = PersonAttribute.where(person_id: person.person_id, person_attribute_type_id: attrib_type).first_or_initialize
        person_attrib.value = params[:person][:attributes][:office_phone_number]
        person_attrib.save
      when 'citizenship'
        attrib_type = PersonAttributeType.find_by_name("Citizenship").id
        person_attrib = PersonAttribute.where(person_id: person.person_id, person_attribute_type_id: attrib_type).first_or_initialize
        person_attrib.value = params[:person][:attributes][:citizenship]
        person_attrib.save

        unless params[:person][:attributes][:race].blank?
          attrib_type = PersonAttributeType.find_by_name("Race").id
          person_attrib = PersonAttribute.where(person_id: person.person_id, person_attribute_type_id: attrib_type).first_or_initialize
          person_attrib.value = params[:person][:attributes][:race]
          person_attrib.save
        end

      when 'occupation'
        attrib_type = PersonAttributeType.find_by_name("Occupation").id
        person_attrib = PersonAttribute.where(person_id: person.person_id, person_attribute_type_id: attrib_type).first_or_initialize
        person_attrib.value = params[:person][:attributes][:occupation]
        person_attrib.save

      end

      print_and_redirect("/patients/print_national_id?patient_id=#{patient.id}", "/patients/patient_demographics/#{patient.id}") and return if print_barcode

    end

    redirect_to "/patients/patient_demographics/#{patient.id}" and return if !patient.id.blank?

    flash["error"] = "Sorry! Something went wrong. Failed to process properly!"

    redirect_to "/" and return

  end

  def show

    @patient = Patient.find(params[:id])
    # raise @patient.inspect
    range = Date.current .beginning_of_day..Date.current.end_of_day

    # unpaid_orders = OrderEntry.select(:order_entry_id,:service_id,:quantity,:amount_paid,
    #                                   :full_price).where('patient_id = ? AND amount_paid < full_price or full_price = 0', @patient.id)
    unpaid_orders = OrderEntry.find_by_sql("select order_entries.*, payments.amount from order_entries left join (select order_entry_id, sum(amount)
                                       as amount from order_payments group by order_entry_id) as payments on
                                       order_entries.order_entry_id = payments.order_entry_id where patient_id = '#{@patient.id}'
                                       AND (amount != full_price or amount is NULL) AND voided != 1;")
    # raise unpaid_orders.inspect
    # raise @patient.inspect
    past_orders = OrderEntry.select(:order_entry_id,:service_id,:quantity, :full_price,:amount_paid,:order_date)
                            .where("patient_id = ? and order_date < ?",  @patient.id, Date.current.beginning_of_day)

    today_payments = Receipt.select(:receipt_number).where("patient_id = ? AND DATE(created_at) = CURDATE()",
                                                           @patient.id)


    @unpaid_orders, @total, @amount_due = view_context.unpaid_records(unpaid_orders)
    @history = view_context.past_records(past_orders)
    @today_payments = view_context.today_records(today_payments)
    @deposits = @patient.amount_deposited

  end

  def patient_by_id

    @settings = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env] rescue {}
    @use_dde = YAML.load_file("#{Rails.root}/config/application.yml")['create_from_dde'] rescue false

    params[:id] = params[:id].strip.gsub(/\s/, "").gsub(/\-/, "") rescue params[:id]

    local_patient = Patient.search_locally(params[:id])

    #if dde settings don't exist
    if !@settings.blank? && @use_dde
      #if dde exists
      @json = local_patient

      @results = []

      if !@json.blank?

        if secure?
          url = "https://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/ajax_process_data"
        else
          url = "http://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/ajax_process_data"
        end

        @results = RestClient.post(url, {:person => @json, :page => params[:page]}, {:accept => :json})

      end

      @dontstop = false

      #processing DDE result
      if JSON.parse(@results).length == 1

        result = JSON.parse(JSON.parse(@results)[0]) #Getting the first person here

        checked = DDE.compare_people(result, @json) # rescue false

        if checked

          result["patient_id"] = @json["patient_id"] if !@json["patient_id"].blank?

          @results = result.to_json

          person = JSON.parse(@results) #["person"]

          if secure?
            url = "https://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/process_confirmation"
          else
            url = "http://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/process_confirmation"
          end

          @results = RestClient.post(url, {:person => person, :target => "select"})

          @dontstop = true

        elsif !checked and @json["names"]["given_name"].blank? and @json["names"]["family_name"].blank? and @json["gender"].blank?

          # result["patient_id"] = @json["patient_id"] if !@json["patient_id"].blank?

          @results = result.to_json

          person = JSON.parse(@results) #["person"]

          if secure?
            url = "https://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/process_confirmation"
          else
            url = "http://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/process_confirmation"
          end

          @results = RestClient.post(url, {:person => person, :target => "select"})

          @dontstop = true

        else

          @results = []

          @results << result

          patient = PatientIdentifier.find_by_identifier(@json["national_id"]).patient rescue nil

          if !patient.nil?

            national_id = ((patient.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil) || params[:id])

            verifier = local_patient.to_json

            checked = DDE.compare_people(result, verifier) # rescue false

            if checked

              result["patient_id"] = @json["patient_id"] if !@json["patient_id"].blank?

              @results = result.to_json

              person = JSON.parse(@results) #["person"]

              if secure?
                url = "https://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/process_confirmation"
              else
                url = "http://#{@settings["dde_username"]}:#{@settings["dde_password"]}@#{@settings["dde_server"]}/process_confirmation"
              end

              @results = RestClient.post(url, {:person => person, :target => "select"})

              @dontstop = true

            end

          else

            @dontstop = true

          end

        end

      elsif JSON.parse(@results).length == 0

        patient = PatientIdentifier.find_by_identifier(@json["national_id"]).patient rescue nil

        if patient.blank?
          redirect_to "/patients/patient_not_found/#{params[:id]}" and return
        else
          @results = []
          @results << local_patient.to_json
          @dontstop = true
        end

      end
    else
      if local_patient.blank? || local_patient["patient_id"].blank?
        #if dde doesn't exist and patient is not available locally
        redirect_to "/patients/patient_not_found/#{params[:id]}" and return
      else
        redirect_to "/patients/#{local_patient['patient_id']}" and return
      end
    end

    render :layout => 'touch'
  end

  def process_result

    use_dde = YAML.load_file("#{Rails.root}/config/application.yml")['create_from_dde'] rescue false
    json = JSON.parse(params["person"]) rescue {}
    if (json["patient"]["identifiers"].class.to_s.downcase == "hash" rescue false)

      tmp = json["patient"]["identifiers"]
      json["patient"]["identifiers"] = []

      (tmp || []).each do |key, value|

        json["patient"]["identifiers"] << {key => value}

      end

    end

    if use_dde
      patient_id = DDE.search_and_or_create(json.to_json, current_location) # rescue nil

      patient = Patient.find(patient_id) rescue nil

    else

      if !json["patient_id"].blank?
        patient = Patient.find_by_patient_id(json['patient_id'])
      elsif !json["national_id"].blank?
        identifier = PatientIdentifier.find_by_identifier(json["national_id"])
        patient = identifier.patient
      else

        json["names"]["family_name2"] = json["names"]["maiden_name"]
        names_params = json["names"].reject{|key,value| key.match(/gender/) }
        names_params = names_params.reject{|key,value| key.match(/maiden_name/) }
        address_params = {
          :state_province => json['addresses']['current_district'],
          :township_division => (json['addresses']['current_residence'].blank? ? json['addresses']['current_ta'] : json['addresses']['current_residence']),
          :city_village => json['addresses']['current_village'],
          :address1 => json['addresses']['landmark'],
          :address2 =>json['addresses']['home_district'],
          :county_district => json['addresses']['home_ta'],
          :neighborhood_cell => json['addresses']['home_village']
        }


        new_person = Person.new
        new_person.gender = json['gender']
        new_person.birthdate = json['birthdate']
        new_person.birthdate_estimated = json['birthdate_estimated']
        new_person.save

        new_person.names.create(names_params)
        new_person.addresses.create(address_params) unless address_params.empty?

        (json["person_attributes"] || []).each do |attribute, value|

          next if value.blank?
          # raise attribute.inspect
          new_person.person_attributes.create(:person_attribute_type_id => PersonAttributeType.find_by_name(attribute).person_attribute_type_id,
                                              :value => value)

        end

        patient = Patient.new
        patient.patient_id = new_person.person_id
        patient.save

        (json["patient"]["identifiers"] || []).each{|identifier|
          identifier_type = PatientIdentifierType.find_by_name("National ID")
          patient.patient_identifiers.create("identifier" => identifier, "identifier_type" => identifier_type.patient_identifier_type_id)
        }

        if patient.patient_identifiers.blank?
          health_center_id = Location.current_health_center.location_id
          national_id_version = "1"
          # national_id_prefix = "PT#{national_id_version}#{health_center_id.to_s.rjust(3,"0")}"
          national_id_prefix = "PT"
          identifier_type = PatientIdentifierType.find_by_name("National ID")
          last_national_id = PatientIdentifier.where("identifier_type = ? AND left(identifier,2)= ?", identifier_type.id, national_id_prefix).order("identifier desc").first
          last_national_id_number = last_national_id.identifier rescue "0"

          next_number = (last_national_id_number[2..6].to_i+1).to_s.rjust(5,"0")
          new_national_id_no_check_digit = "#{national_id_prefix}#{next_number}"
          check_digit = PatientIdentifier.calculate_checkdigit(new_national_id_no_check_digit[2..-1])
          new_national_id = "#{new_national_id_no_check_digit}#{check_digit}"
          patient_identifier = PatientIdentifier.new
          patient_identifier.type = identifier_type
          patient_identifier.identifier = new_national_id
          patient_identifier.patient = patient
          patient_identifier.save
        end

        patient_id = patient.patient_id
      end

    end

    #if print barcode
    print_and_redirect("/patients/print_national_id?patient_id=#{patient_id}", "/patients/#{patient.id}") and return if !patient.blank? and (json["print_barcode"] rescue false)


    redirect_to "/patients/#{patient.id}" and return if !patient.blank?

    flash["error"] = "Sorry! Something went wrong. Failed to process properly!"

    redirect_to "/" and return

  end

  def ajax_process_data

    settings = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env] rescue {}
    use_dde = YAML.load_file("#{Rails.root}/config/application.yml")['create_from_dde'] rescue false

    person = params[:person] rescue {}
    result = []
    json = JSON.parse(params[:person]) rescue {}

    if !person.blank?

      if use_dde
        if secure?
          url = "https://#{settings["dde_username"]}:#{settings["dde_password"]}@#{settings["dde_server"]}/ajax_process_data"
        else
          url = "http://#{settings["dde_username"]}:#{settings["dde_password"]}@#{settings["dde_server"]}/ajax_process_data"
        end

        results = RestClient.post(url, {:person => person, :page => params[:page]}, {:accept => :json})

        result = JSON.parse(results)

        patient = PatientIdentifier.find_by_identifier(json["national_id"]).patient rescue nil

        if !patient.nil?

          name = patient.person.names.last rescue nil

          address = patient.person.addresses.last rescue nil

          result << {
            "_id" => json["national_id"],
            "patient_id" => (patient.patient_id rescue nil),
            "local" => true,
            "names" =>
              {
                "family_name" => (name.family_name rescue nil),
                "given_name" => (name.given_name rescue nil),
                "middle_name" => (name.middle_name rescue nil),
                "maiden_name" => (name.family_name2 rescue nil)
              },
            "gender" => (patient.person.gender rescue nil),
            "person_attributes" => {
              "occupation" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Occupation").id).value rescue nil),
              "cell_phone_number" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Cell Phone Number").id).value rescue nil),
              "home_phone_number" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Home Phone Number").id).value rescue nil),
              "office_phone_number" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Office Phone Number").id).value rescue nil),
              "race" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Race").id).value rescue nil),
              "country_of_residence" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Country of Residence").id).value rescue nil),
              "citizenship" => (patient.person.person_attributes.find_by_person_attribute_type_id(PersonAttributeType.find_by_name("Citizenship").id).value rescue nil)
            },
            "birthdate" => (patient.person.birthdate rescue nil),
            "patient" => {
              "identifiers" => (patient.patient_identifiers.collect { |id| {id.type.name => id.identifier} if id.type.name.downcase != "national id" }.delete_if { |x| x.nil? } rescue [])
            },
            "birthdate_estimated" => ((patient.person.birthdate_estimated rescue 0).to_s.strip == '1' ? true : false),
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
      else
        #when dde not available

        #get similar records
        records = Person.joins(:names).where(person_name: {given_name: json["names"]["given_name"],
                                                           family_name:json["names"]["family_name"]},
                                             gender: json["names"]["gender"])

        if records.length < 15
          matching_people = records.collect{| person |
            person.person_id
          }

          # raise matching_people.to_yaml

          people_like = Person.joins(:names =>[:person_name_code]).where(person_name_code: {given_name_code: json["names"]["given_name"].soundex, family_name_code:json["names"]["family_name"].soundex}, gender: json["names"]["gender"]).where.not(person_id: matching_people).order("person_name.given_name ASC, person_name_code.family_name_code ASC")
          records = records + people_like
        end
        result = view_context.patient_list(records)

      end

      result = result.to_json

    end

    render :body => result
  end

  def process_confirmation

    @json = params[:person] rescue {}

    @results = []

    settings = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env] rescue {}
    use_dde = YAML.load_file("#{Rails.root}/config/application.yml")['create_from_dde'] rescue false

    if (!settings.blank? && use_dde)
      target = params[:target]

      target = "update" if target.blank?

      if !@json.blank?
        if secure?
          url = "https://#{settings["dde_username"]}:#{settings["dde_password"]}@#{settings["dde_server"]}/process_confirmation"
        else
          url = "http://#{settings["dde_username"]}:#{settings["dde_password"]}@#{settings["dde_server"]}/process_confirmation"
        end
        @results = RestClient.post(url, {:person => @json, :target => target}, {:accept => :json})
      end
    else
      @results = @json
    end


    render :json => @results
  end

  def patient_not_found
    @id = params[:id]

    redirect_to "/" and return if !params[:create].blank? and params[:create] == "false"
  end

  def print_national_id
    @patient = Patient.find(params[:patient_id])
    print_string = Misc.patient_national_id_label(@patient)
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def district
    region_id = Region.find_by_name("#{params[:filter_value]}").id
    region_conditions = ["name LIKE (?) AND region_id = ? ", "#{params[:search_string]}%", region_id]

    districts = District.all.where( region_conditions).order('name')
    districts = districts.map do |d|
      "<li value=\"#{d.name}\">#{d.name}</li>"
    end
    render :plain => districts.join('') + "<li value='Other'>Other</li>" and return
  end


  # def district
  #   @districts = District.all.collect{|x| [x.district_id, x.name]}
  #   raise @districts.inspect
  #   region = Region.find_by_name(params[:filter_value])
  
  #   if region
  #     # Query for districts based on the search_string and region_id
  #     districts = District.where("name LIKE ? AND region_id = ?", " #{params[:search_string]}%", region.id).order('name')
  
  #     # Return an array of district names
  #     district_names = districts.pluck(:name)  # Get an array of district names
  #     district_names << 'Other'  # Add 'Other' as a suggestion
  #     render json: district_names  # Respond with the array as JSON
  #   else
  #     render json: ['Other']  # If no region is found, return only 'Other'
  #   end
  # end
  

  # List traditional authority containing the string given in params[:value]
  def traditional_authority
    district_id = District.find_by_name("#{params[:filter_value]}").id
    traditional_authority_conditions = ["name LIKE (?) AND district_id = ?", "%#{params[:search_string]}%", district_id]

    traditional_authorities = TraditionalAuthority.all.where(traditional_authority_conditions).order('name')
    traditional_authorities = traditional_authorities.map do |t_a|
      "<li value=\"#{t_a.name}\">#{t_a.name}</li>"
    end
    render :plain => traditional_authorities.join('') + "<li value='Other'>Other</li>" and return
  end

  # Villages containing the string given in params[:value]
  def village
    traditional_authority_id = TraditionalAuthority.find_by_name("#{params[:filter_value]}").id
    village_conditions = ["name LIKE (?) AND traditional_authority_id = ?", "%#{params[:search_string]}%", traditional_authority_id]

    villages = Village.all.where(village_conditions).order('name')
    villages = villages.map do |v|
      "<li value=\"#{v.name}\">#{v.name}</li>"
    end
    render :plain => villages.join('') + "<li value='Other'>Other</li>" and return
  end

  # Landmark containing the string given in params[:value]
  def landmark

    landmarks = ["", "Market", "School", "Police", "Church", "Borehole", "Graveyard"]
    landmarks = landmarks.map do |v|
      "<li value='#{v}'>#{v}</li>"
    end
    render :plain => landmarks.join('') + "<li value='Other'>Other</li>" and return
  end

  # Countries containing the string given in params[:value]
  def country
    country_conditions = ["name LIKE (?)", "%#{params[:search_string]}%"]

    countries = Country.all.where(country_conditions).order('weight')
    countries = countries.map do |v|
      "<li value=\"#{v.name}\">#{v.name}</li>"
    end
    render :text => countries.join('') + "<li value='Other'>Other</li>" and return
  end

  # Nationalities containing the string given in params[:value]
  def nationality
    nationalty_conditions = ["name LIKE (?)", "%#{params[:search_string]}%"]

    nationalities = Nationality.all.where(nationalty_conditions).order('weight')
    nationalities = nationalities.map do |v|
      "<li value=\"#{v.name}\">#{v.name}</li>"
    end
    render :text => nationalities.join('') + "<li value='Other'>Other</li>" and return
  end

  def family_names
    searchname("family_name", params[:search_string])
  end

  def given_names
    searchname("given_name", params[:search_string])
  end

  def family_name2
    searchname("family_name2", params[:search_string])
  end

  def middle_name
    searchname("middle_name", params[:search_string])
  end

  def searchname(field_name, search_string)
    @names = PersonNameCode.find_most_common(field_name, search_string).collect{|person_name| person_name.send(field_name)} # rescue []
    render :body => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end

  def secure?
    @settings = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env]
    secure = @settings["secure_connection"] rescue false
  end

  def patient_not_found
    if request.post?
      if params[:create] == "true"
        redirect_to "/patients/new?identifier=#{params[:id]}" and return
      else
        redirect_to "/" and return
      end
    else
      @id = params[:id]
      render :layout => 'touch'
    end
  end

  def update_attributes
    raise params.inspect
  end
end
