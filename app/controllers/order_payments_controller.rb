class OrderPaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:void]

  def create
    if params[:order_entries].blank?
      orders = OrderEntry.where("patient_id = ? AND (amount_paid < full_price OR full_price = 0)", params[:order_payment][:patient_id])
    else
      orders = OrderEntry.where(patient_id: params[:order_payment][:patient_id], order_entry_id: params[:order_entries].split(','))
    end
  
    # Debug received parameters
    puts "Received amount: #{params[:order_payment][:amount]}"
    puts "Received deposits: #{params[:order_payment][:deposits]}"
  
    amount = params[:order_payment][:amount].to_f + params[:order_payment][:deposits].to_f
  
    if amount > 0 || orders.any? { |entry| entry.full_price == 0 }
      Receipt.transaction do
        cashier = User.find(params[:creator]) # Fetch once, reuse
        patient_id = params[:order_payment][:patient_id]
        
        new_receipt = Receipt.create!(
          payment_mode: params[:order_payment][:mode],
          cashier: cashier,
          patient_id: patient_id
        )
  
        order_payments = []
  
        orders.each do |entry|
          next if entry.status[:bill_status] == "PAID" && entry.full_price > 0
  
          pay_amount = if entry.full_price == 0
                         0 # Zero-price services should be treated as paid
                       else
                         [entry.full_price - entry.status[:amount], amount].min
                       end
  
          # Debug pay_amount calculations
          puts "Processing order_entry_id: #{entry.id}, full_price: #{entry.full_price}, status amount: #{entry.status[:amount]}, pay_amount: #{pay_amount}"
  
          entry.update!(amount_paid: entry.amount_paid + pay_amount)
          amount -= pay_amount
  
          puts "Remaining amount after payment: #{amount}"
  
          order_payments << {
            order_entry_id: entry.id,
            cashier: cashier.id,
            amount: pay_amount,
            receipt_number: new_receipt.receipt_number,
            created_at: Time.current,
            updated_at: Time.current
          }
        end
  
        # Debug final order payments data before inserting
        puts "Final Order Payments Data: #{order_payments.inspect}"
  
        OrderPayment.insert_all(order_payments) unless order_payments.empty?
  
        if amount >= params[:order_payment][:deposits].to_f
          amount -= params[:order_payment][:deposits].to_f
          deposit_used = 0
        else
          deposit_used = params[:order_payment][:deposits].to_f - amount
          deposits = Deposit.where("patient_id = ? AND amount_available > 0", patient_id).order(:created_at)
  
          deposits.each do |deposit|
            break if deposit_used == 0
            used_amount = [deposit.amount_available, deposit_used].min
            deposit.update!(amount_available: deposit.amount_available - used_amount, updated_by: cashier.id)
            deposit_used -= used_amount
          end
          amount = 0
        end
  
        patient = Patient.find(patient_id)
        dob = Person.where(person_id: patient.id).pluck(:birthdate).first
        age = calculate_age(dob)
  
        if age > 1825
          print_and_redirect("/order_payments/print_receipt?deposit=#{deposit_used}&change=#{amount}&ids=#{new_receipt.receipt_number}",
                            "/patients/#{patient_id}")
        else
          just_redirect("/patients/#{patient_id}")
        end
      end
    else
      redirect_to "/patients/#{params[:order_payment][:patient_id]}" and return
    end
  end  

  def void_entry
    entries = OrderEntry.where(order_entry_id: params[:void_ids])

    if entries.blank?
      render json: { error: "No entries found" }, status: 404 and return
    end

    receipts = OrderPayment.where(order_entry_id: entries.pluck(:order_entry_id)).pluck(:receipt_number).uniq
    OrderPayment.where(receipt_number: receipts).update_all(voided: true, voided_by: current_user.id)
    Receipt.where(receipt_number: receipts).update_all(voided: true, voided_by: current_user.id)

    if receipts.blank?
      redirect_to "/patients/#{params[:patient_id]}" and return
    else
      old_receipt = Receipt.find_by(receipt_number: receipts.first)
      new_receipt = Receipt.create!(
        payment_mode: old_receipt.payment_mode,
        patient_id: entries.first.patient_id,
        cashier: current_user
      )

      OrderPayment.where(receipt_number: receipts).update_all(receipt_number: new_receipt.receipt_number)
      print_and_redirect("/order_payments/print_receipt?ids=#{new_receipt.receipt_number}",
                         "/patients/#{params[:patient_id]}")
    end
  end

  def print_receipt
    ids = params[:ids]&.split(',') || [params[:id]]
    change = params[:change].to_f
    deposit = params[:deposit].to_f

    print_string = ids.map { |receipt| Misc.print_receipt(receipt, deposit, change) }.join("\n")

    send_data(print_string, type: "application/label; charset=utf-8", stream: false,
              filename: "#{SecureRandom.alphanumeric(9)}.lbs", disposition: "inline")
  end

  def void
    entries = OrderEntry.where(order_entry_id: params[:void_ids].split(','))
    receipts = []
    if entries.blank?
      redirect_to "/patients/#{params[:patient_id]}"
    else
      # Voiding selected entries
      (entries || []).each do |entry|
        (entry.order_payments || []).each do |payment|
          payment.void(params[:void_reason], current_user)
          receipts << payment.receipt_number
        end
        entry.void(params[:void_reason], current_user.id)
      end

      if receipts.blank?
        redirect_to "/patients/#{params[:patient_id]}"
      else
        other_payments = OrderPayment.where(receipt_number: receipts)
        old_receipt = Receipt.where(receipt_number: receipts).first
        Receipt.where(receipt_number: receipts).update_all(voided: true, voided_by: current_user)

        if other_payments.blank?
          redirect_to entries.first.patient and return
        else
          Receipt.transaction do
            new_receipt = Receipt.create(
              payment_mode: old_receipt.payment_mode,
              patient_id: other_payments.first.order_entry.patient_id,
              cashier: current_user
            )
            OrderPayment.where(receipt_number: receipts).update_all(receipt_number: new_receipt.receipt_number)

            print_and_redirect("/order_payments/print_receipt?ids=#{new_receipt.receipt_number}",
                               "/patients/#{params[:patient_id]}")
          end
        end
      end
    end
  end

  private

  def calculate_age(dob)
    require 'date'
    today = Date.today
    dob = dob.is_a?(Date) ? dob : Date.parse(dob.to_s)
    (today - dob).to_i
  end
end