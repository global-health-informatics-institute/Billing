class OrderPaymentsController < ApplicationController
  def show

  end
  def create

    if params[:order_entries].blank?
      range = Date.current.beginning_of_day..Date.current.end_of_day
      orders = OrderEntry.where("patient_id = ? and amount_paid < full_price", params[:order_payment][:patient_id])
      #orders = OrderEntry.select(:order_entry_id, :full_price,:amount_paid).where(
      #  "patient_id = ? and amount_paid < full_price", params[:order_payment][:patient_id])

    else
      orders = OrderEntry.where(patient_id: params[:order_payment][:patient_id],order_entry_id: params[:order_entries].split(','))
      #orders = OrderEntry.select(:order_entry_id, :full_price,:amount_paid).where(patient_id: params[:order_payment][:patient_id],
      #                                                                            order_entry_id: params[:order_entries].split(','))
    end

    amount = params[:order_payment][:amount].to_f + params[:order_payment][:deposits].to_f
    if amount > 0
      Receipt.transaction do
        new_receipt = Receipt.create(payment_mode: params[:order_payment][:mode],
                                     cashier: User.find(params[:creator]),
                                     patient_id: params[:order_payment][:patient_id])

        (orders || []).each do |entry|
          break if amount == 0
          order_status = entry.status
          if order_status[:bill_status] == "PAID"
            next
          else
            amount_due = (entry.full_price - order_status[:amount])
            pay_amount =  (amount_due <= amount ? amount_due : amount)

            entry.amount_paid += pay_amount

            entry.save

            OrderPayment.create(order_entry_id: entry.id, cashier: User.find(params[:creator]),
                                amount: pay_amount, receipt_number: new_receipt.receipt_number )

            amount -= pay_amount

          end
        end

        if amount >= params[:order_payment][:deposits].to_f
          amount =  amount - params[:order_payment][:deposits].to_f
          deposit_used = 0
        else
          #Update deposits

          deposit_used = params[:order_payment][:deposits].to_f - amount

          deposits = Deposit.where("patient_id = ? AND amount_available > ?", params[:order_payment][:patient_id],0.00)
          (deposits || []).each do |deposit|
            break if deposit_used == 0
            used_amount = (deposit.amount_available >= deposit_used ? deposit_used : deposit.amount_available)
            deposit.amount_available -= used_amount
            deposit.updated_by = params[:creator]
            deposit.save
            deposit_used -= used_amount
          end
          amount = 0
        end

        #Print receipt of transaction
        print_and_redirect("/order_payments/print_receipt?deposit=#{deposit_used}&change=#{amount}&ids=#{new_receipt.receipt_number}",
                           "/patients/#{params[:order_payment][:patient_id]}")
      end

    else
      redirect_to "/patients/#{params[:order_payment][:patient_id]}" and return
    end

  end

  def print_receipt
    ids = params[:ids].split(',') rescue params[:id]
    change = (params[:change].to_f || 0)
    deposit = (params[:deposit].to_f || 0)
    if ids.length > 1
      print_string = ""
      (ids || []).each do |receipt|
        print_string += "#{Misc.print_receipt(receipt, deposit, change)}\n"
      end
    else
      print_string = Misc.print_receipt(ids, deposit, change)
    end


    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false,
              :filename=>"#{(0..8).map { (65 + rand(26)).chr }.join}.lbs", :disposition => "inline")

  end

  def void
    #This function cancels payments and reprints the receipt
    entries = OrderEntry.where(order_entry_id: params[:void_ids].split(','))
    receipts = []
    if entries.blank?
      redirect_to "/patients/#{params[:patient_id]}"
    else

      #voiding selected entries
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
            new_receipt = Receipt.create(payment_mode: old_receipt.payment_mode,
                                         patient_id: other_payments.first.order_entry.patient_id, cashier: current_user)
            OrderPayment.where(receipt_number: receipts).update_all(receipt_number: new_receipt.receipt_number)

            print_and_redirect("/order_payments/print_receipt?ids=#{new_receipt.receipt_number}",
                               "/patients/#{params[:patient_id]}")
          end
        end
      end

    end
  end
end
