class Region < ActiveRecord::Base
  #establish_connection Registration
  self.table_name = "region"
  self.primary_key = "region_id"


end
