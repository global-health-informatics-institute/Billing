class District < ActiveRecord::Base
  #establish_connection Registration
  self.table_name = "dde_district"
  self.primary_key = "district_id"

  belongs_to :region

end
