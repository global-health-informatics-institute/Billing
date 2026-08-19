class NormalizeServiceUnits < ActiveRecord::Migration[6.0]
  class Service < ActiveRecord::Base
    self.table_name = 'services'
  end

  def up
    Service.where(voided: false).where.not(unit: '1').update_all(unit: '1')
    Service.where(voided: false, unit: nil).update_all(unit: '1')
  end

  def down
    # No rollback needed for data normalization
  end
end
