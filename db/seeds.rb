# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
creator = User.first
service_types = %w[Consultation Radiology Pharmacy Laboratory Admission Documentation Surgery Mortuary Maternity Dental Ophthalmology Other\ Procedures]
puts 'Loading Service types'
(service_types || []).each do |type|
  service_type = ServiceType.where(name: type).first_or_initialize
  service_type.creator = creator.id
  service_type.save
end

puts 'Loading services and their prices'
CSV.foreach("#{Rails.root}/db/final_service_seed.csv",:headers=>:true) do |row|
  type = ServiceType.where(name: row[2]).first.id
  service = Service.where({name: row[0], unit: row[1], service_type_id: type}).first_or_initialize
  service.rank = (row[5].blank? ? 999 : row[5])
  service.creator = creator.id
  service.save

  service_price = ServicePrice.where(service_id: service.id,price_type: row[4]).first_or_initialize
  service_price.price = (row[3].blank? ? 0.00 : row[3].to_f)
  service_price.creator = creator.id
  service_price.updated_by = creator.id
  service_price.save
end

puts 'Loading service panels'
CSV.foreach("#{Rails.root}/db/panel_seed.csv",:headers=>:true) do |row|
  type = ServiceType.where(name: row[3]).first.id
  service_panel = ServicePanel.where({name: row[0], service_type_id: type}).first_or_initialize
  service_panel.creator = creator.id
  service_panel.save

  service = Service.where({name: row[1], service_type_id: type}).first
  next if service.blank?

  panel_detail = ServicePanelDetail.where(service_panel_id: service_panel.id).first_or_initialize
  panel_detail.service_id = service.id
  panel_detail.quantity = row[2]
  panel_detail.save
end