class District < ActiveRecord::Base
  #establish_connection Registration
  self.table_name = "district"
  self.primary_key = "district_id"

  belongs_to :region
  has_many :traditional_authorities

  def collected_villages
    # This code retrieves village names along with their traditional authority and district names
    villages = Village.joins(traditional_authority: :district)
                      .select("village.village_id AS village_id, 
                               village.name AS village_name, 
                               traditional_authority.name AS traditional_authority_name, 
                               district.name AS district_name")
  
    # Collects and returns only the village names
    villages.collect(&:village_name)
  end
  


end
