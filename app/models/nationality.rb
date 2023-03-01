class Nationality < ActiveRecord::Base
  #establish_connection Registration

  self.table_name = "dde_nationality"
  self.primary_key = "nationality_id"

  belongs_to :region
end
