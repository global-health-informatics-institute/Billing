creator = User.first


puts 'Renaming services'
CSV.foreach("#{Rails.root}/db/renamed_services.csv",{:headers=>:first_row, :col_sep => ","}) do |row|
  service = Service.where(name: row[0]).first
  next if service.blank?
  service.name = row[1]
  service.save
end

puts 'Loading services and their prices'
CSV.foreach("#{Rails.root}/db/updated_list_final.csv",{:headers=>:first_row, :col_sep => ","}) do |row|
  type = ServiceType.where(name: row[1]).first.id rescue nil
  next if type.blank?
  service = Service.where({name: row[0], service_type_id: type}).first_or_initialize
  service.unit = row[4].strip
  service.rank = (row[5].to_i)
  service.creator = creator.id
  service.save

  if row[6] == 'TRUE'
    service.voided = true
    service.voided_by = creator.id
    service.voided_reason = "Duplicate"
    service.voided_date = Date.current
    service.save
  else
    if !row[2].blank? || row[2] == '0'
      service_price = ServicePrice.where(service_id: service.id,price_type: 'General').first_or_initialize
      service_price.price = (row[2].blank? ? 0.00 : row[2].to_f)
      service_price.creator = creator.id
      service_price.updated_by = creator.id
      service_price.save
    end

    if !row[3].blank? || row[3] == '0'
      service_price = ServicePrice.where(service_id: service.id,price_type: 'Private').first_or_initialize
      service_price.price = (row[3].blank? ? 0.00 : row[3].to_f)
      service_price.creator = creator.id
      service_price.updated_by = creator.id
      service_price.save
    end
  end

end

puts 'Loading service panels'
CSV.foreach("#{Rails.root}/db/panel_seed.csv",{:headers=>:first_row, :col_sep => ","}) do |row|
  type = ServiceType.where(name: row[3]).first.id
  service_panel = ServicePanel.where({name: row[0], service_type_id: type}).first_or_initialize
  service_panel.creator = creator.id
  service_panel.voided = row[4]
  service_panel.save

  service = Service.where({name: row[1], service_type_id: type}).first
  next if service.blank?

  panel_detail = ServicePanelDetail.where(service_panel_id: service_panel.id).first_or_initialize
  panel_detail.service_id = service.id
  panel_detail.quantity = row[2]
  panel_detail.save
end