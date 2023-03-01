class Country < ActiveRecord::Base
  #establish_connection Registration
  self.table_name = "dde_country"
  self.primary_key = "country_id"

  belongs_to :region

end
