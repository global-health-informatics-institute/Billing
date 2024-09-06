#This module includes all functions that may come in handy to do avoid code repetitions
module Misc
  def self.patient_national_id_label(patient)

    return unless patient.national_id
    sex =  "(#{patient.gender.upcase})"

    address = patient.current_district rescue ""
    if address.blank?
      address = patient.current_residence rescue ""
    else
      address += ", " + patient.current_residence unless patient.current_residence.blank?
    end

    label = ZebraPrinter::Label.new(609,450,'026',false)
    label.font_size = 2
    label.font_horizontal_multiplier = 2
    label.font_vertical_multiplier = 2
    label.left_margin = 40
    label.draw_barcode(40,180,0,1,3,9,80,false,"#{patient.national_id}")
    label.draw_multi_text("#{patient.full_name.titleize}")
    label.draw_multi_text("#{patient.presentable_dob}#{sex}")
    label.draw_multi_text("#{dash_formatter(patient.national_id)}")
    label.draw_multi_text("#{address}" ) unless address.blank?
    label.draw_qr_barcode(440,60,'Q','m2','s5',"#{patient.full_name.titleize}~#{patient.national_id}~#{patient.dob}~#{sex}~#{address}")
    label.print(1)
  end

  def self.dash_formatter(id)
    return "" if id.blank?
    if id.length > 9
      return id[0..(id.length/3)] + "-" +id[1 +(id.length/3)..(id.length/3)*2]+ "-" +id[1 +2*(id.length/3)..id.length]
    else
      return id[0..(id.length/2) -1] + "-" +id[(id.length/2)..id.length]
    end
  end

  def self.print_receipt(ids,deposit = 0, change = 0)
    receipt = Receipt.where(receipt_number: ids).first

    payments = receipt.order_payments
    patient_name = receipt.patient.full_name
    patient_id = receipt.patient.national_id
    cashier = receipt.cashier.name
    receipt_number = receipt.receipt_number
    text = []
    heading = ""
    heading += "#{get_config('facility_name').titleize}\n"
    heading += "#{get_config('facility_address')}\n"
    heading += "Date: #{Date.current.strftime('%d %b %Y')}\n"
    heading += "Patient: #{patient_name.titleize}\n"
    heading += "Patient ID: #{patient_id}\n"
    heading += "Issued By: #{cashier.titleize}\n"
    total = 0
    (payments || []).each do |payment|
      text << [payment.service.name, local_currency(payment.amount)]
      total += payment.amount
    end

    label = ZebraPrinter::Label.new(616,203,'056',true)
    label.font_size = 3
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.draw_text("Receipt",250,0,0,2,1,2,false)
    label.draw_text(receipt_number,450,0,0,3,1,1,false)
    label.y+=10
    label.draw_multi_text(heading)
    label.draw_line(label.x,label.y,566,2)
    label.y+=10
    label.draw_table(text, [[370, "left"], [200, "right"]])
    label.draw_line(label.x,label.y,566,2)
    label.y+=10
    label.draw_table([['Total: ',local_currency(total)]], [[370, "left"], [200, "right"]])
    if (deposit > 0 )
      label.draw_table([['Deposit: ',local_currency((-1 * deposit))]], [[370, "left"], [200, "right"]])
    end
    label.draw_table([['Cash: ',local_currency((total+change))]], [[370, "left"], [200, "right"]])
    label.draw_table([['Change: ',local_currency(change)]], [[370, "left"], [200, "right"]])
    label.draw_line(label.x,label.y,566,7,1)
    label.print(1)
  end

  def self.get_config(prop)
    YAML.load_file("#{Rails.root}/config/application.yml")[prop]
  end

  def self.local_currency(amount)
    return ActiveSupport::NumberHelper::number_to_currency(amount,{precision: 2,unit: 'MWK '})
  end

  def self.print_location(location_id)
    location = Location.find(location_id)
    label = ZebraPrinter::Label.new(801,329,'026',false)
    label.font_size = 2
    label.font_horizontal_multiplier = 2
    label.font_vertical_multiplier = 2
    label.left_margin = 50
    label.draw_barcode(50,180,0,1,5,15,120,false,"#{location.location_id}")
    label.draw_multi_text("#{location.name}")
    label.print(1)
  end

  def self.print_summary(data,totals,date,cashier,hour)
    heading = ""
    heading += "Date: #{date}\n"
    heading += "Working Hour: #{hour}\n"
    heading += "Total:#{local_currency(totals[:general] + totals[:private])}\n"
    heading += "Cashier Name:#{cashier.titleize}\n"
    heading += "Checked By: \n Banked By:\n Dept Head: \n Account G.M: \n"

    label = ZebraPrinter::Label.new(616,203,'056',true)
    label.font_size = 3
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.draw_text("#{get_config('facility_name').titleize}",200,0,0,2,1,2,false)
    label.y+=20
    label.draw_text("Daily Cash Summary",200,label.y,0,3,1,1,false)
    label.y+=30
    label.draw_multi_text(heading)
    label.y+=20
    label.draw_text("General",200,label.y,0,2,1,2,false)
    label.y+=30
    (data || []).each do |id,record|
      label.draw_table([[record[:name].upcase,local_currency(record[:general])]], [[370, "left"], [200, "right"]])
    end
    label.y+=10
    label.draw_table([['Total',local_currency(totals[:general])]], [[370, "left"], [200, "right"]])
    label.y+=10
    label.draw_text("Private",200,label.y,0,2,1,2,false)
    label.y+=30
    (data || []).each do |id,record|
      label.draw_table([[record[:name].upcase,local_currency(record[:private])]], [[370, "left"], [200, "right"]])
      label.y+=10
    end
    label.y+=20
    label.draw_table([['Total',local_currency(totals[:private])]], [[370, "left"], [200, "right"]])

    label.print(1)
  end

  def self.print_deposit_receipt(id)
    receipt = Deposit.find_by_deposit_id(id)

    patient_name = receipt.patient.full_name
    cashier = receipt.creator.name
    receipt_number = receipt.receipt_number

    heading = ""
    heading += "#{get_config('facility_name').titleize}\n"
    heading += "#{get_config('facility_address')}\n"
    heading += "Date: #{Date.current.strftime('%d %b %Y')}\n"
    heading += "Patient: #{patient_name.titleize}\n"
    heading += "Issued By: #{cashier.titleize}\n"

    text = [['Amount Deposited', local_currency(receipt.amount_received)]]


    label = ZebraPrinter::Label.new(616,203,'056',true)
    label.font_size = 3
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.draw_text("Deposit Receipt",250,0,0,2,1,2,false)
    label.draw_text(receipt_number,450,0,0,3,1,1,false)
    label.y+=10
    label.draw_multi_text(heading)
    label.draw_line(label.x,label.y,566,2)
    label.y+=10
    label.draw_table(text, [[370, "left"], [200, "right"]])
    label.draw_line(label.x,label.y,566,2)
    label.y+=10
    label.draw_table([['Total: ',local_currency(receipt.amount_received)]], [[370, "left"], [200, "right"]])
    label.draw_line(label.x,label.y,566,7,1)
    label.print(1)
  end

  def self.print_refund_receipt(data)
    patient_name = data['patient_name']
    cashier = data['cashier_name']

    heading = ""
    heading += "#{get_config('facility_name').titleize}\n"
    heading += "#{get_config('facility_address')}\n"
    heading += "Date: #{Date.current.strftime('%d %b %Y')}\n"
    heading += "Patient: #{patient_name.titleize}\n"
    heading += "Issued By: #{cashier.titleize}\n"

    text = [['Amount Deposited', local_currency(data['amount_received'])],
            ['Amount Used', local_currency(data['amount_used'])]]


    label = ZebraPrinter::Label.new(616,203,'056',true)
    label.font_size = 3
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.draw_text("Deposit Refund",250,0,0,2,1,2,false)
    label.y+=10
    label.draw_multi_text(heading)
    label.draw_line(label.x,label.y,566,2)
    label.y+=10
    label.draw_table(text, [[370, "left"], [200, "right"]])
    label.draw_line(label.x,label.y,566,2)
    label.y+=10
    label.draw_table([['Refund Amount: ',local_currency(data['balance'])]], [[370, "left"], [200, "right"]])
    label.draw_line(label.x,label.y,566,7,1)
    label.print(1)
  end
end