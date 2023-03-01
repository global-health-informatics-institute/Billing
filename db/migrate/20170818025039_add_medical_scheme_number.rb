class AddMedicalSchemeNumber < ActiveRecord::Migration[6.0]
  def change
    change_table :patient_accounts do |p|
      p.string :scheme_number
    end
  end

end
