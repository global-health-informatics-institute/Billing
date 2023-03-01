class DepositsController < ApplicationController
  def new
    render layout: 'touch'
  end

  def create

    new_deposit = Deposit.new()
    new_deposit.amount_received= params[:deposit][:amount_received]
    new_deposit.amount_available= params[:deposit][:amount_received]
    new_deposit.creator = User.find_by_user_id(params[:deposit][:creator])
    new_deposit.patient_id= params[:deposit][:patient_id]
    new_deposit.save

    if new_deposit.errors.blank?
      print_and_redirect("/patients/#{params[:patient_id]}/deposits/#{new_deposit.id}",
                         "/patients/#{params[:patient_id]}")

    else
      redirect_to "/patients/#{params[:patient_id]}"
    end

  end

  def index
    @patient = Patient.find(params[:patient_id])
    @deposits = Deposit.where(patient_id: params[:patient_id]).order("amount_available DESC, created_at DESC")
    @amount = 0
    (@deposits || []).each do |deposit|
      @amount += deposit.amount_available
    end
  end

  def show
    print_string = Misc.print_deposit_receipt(params[:id])

    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false,
              :filename=>"#{(0..8).map { (65 + rand(26)).chr }.join}.lbs", :disposition => "inline")
  end

  def reclaim_deposit

    @redirect_url = "/patients/#{params[:patient_id]}/deposits"
    deposits = Deposit.where('patient_id = ? AND amount_available > ?', params[:patient_id],0)

    redirect_to @redirect_url if deposits.blank?

    patient = Patient.find_by_patient_id(params[:patient_id])
    patient_name = patient.full_name
    cashier_name = current_user.name
    amount_received =  0
    balance = 0
    amount_used = 0

    (deposits || []).each do |deposit|
      balance += deposit.amount_available
      amount_used += (deposit.amount_received - deposit.amount_available)
      amount_received += deposit.amount_received
      deposit.amount_available = 0
      deposit.updated_by = current_user.id
      deposit.save
    end
    print_path = "/print_refund?cashier_name=#{cashier_name}&balance=#{balance}&amount_used=#{amount_used}&amount_received=#{amount_received}&balance=#{balance}&patient_name=#{patient_name}"
    print_and_redirect(print_path, "/patients/#{params[:patient_id]}/deposits")

  end

  def print_refund
    print_string = Misc.print_refund_receipt(params)
    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false,
              :filename=>"#{(0..8).map { (65 + rand(26)).chr }.join}.lbs", :disposition => "inline")

  end

  private

  def deposit_params
    params.require(:deposit).permit(:amount_received,:patient_id, :creator)
  end
end
