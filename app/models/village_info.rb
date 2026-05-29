class VillageInfo < ApplicationRecord
    self.primary_key = :district_id

    self.table_name = 'village_info'
end
