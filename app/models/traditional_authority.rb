class TraditionalAuthority< ActiveRecord::Base
    #establish_connection Registration
    self.table_name = "traditional_authority"
    self.primary_key = "traditional_authority_id"

    belongs_to :district
    has_many:villages

  
  end