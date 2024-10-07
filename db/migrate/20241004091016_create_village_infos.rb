class CreateVillageInfos < ActiveRecord::Migration[6.1]
  def change
    create_table :village_infos do |t|

      t.timestamps
    end
  end
end
