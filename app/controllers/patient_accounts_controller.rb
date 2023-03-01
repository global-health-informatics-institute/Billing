class PatientAccountsController < ApplicationController
  def index

  end

  def new
    @providers = MedicalSchemeProvider.all.collect{|x| x.company_name}
    render :layout => 'touch'
  end

  def create
    PatientAccount.transaction do
      old_account = PatientAccount.where(patient_id: params[:patient_id], active: true).last
      unless old_account.blank?
        old_account.active.false
        old_account.save
      end
      new_account = PatientAccount.new
      new_account.patient_id= params[:patient_id]
      new_account.medical_scheme_id = params[:patient_account][:scheme]
      new_account.scheme_number = params[:patient_account][:scheme_number]
      new_account.creator = params[:patient_account][:creator]
      new_account.active_from = DateTime.current
      new_account.active = true
      new_account.save
    end

    redirect_to "/patients/#{params[:patient_id]}"
  end

  def edit

  end

  def update

  end

  def destroy

  end
end
