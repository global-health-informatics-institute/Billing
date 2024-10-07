class Village< ActiveRecord::Base
  #establish_connection Registration
  self.table_name = "village"
  self.primary_key = "village_id"
  belongs_to :traditional_authority
  belongs_to :district

end