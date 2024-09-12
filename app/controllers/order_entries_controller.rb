class OrderEntriesController < ApplicationController
  def show

  end

  def new
    @categories = Hash[*ServiceType.select(:name,:service_type_id).where(service_type_id: 13).collect{|x|[x.name,(x.top_ten_services + ['Others'])]}.flatten(1)]
    # @categories = ServiceType.find(13)
    render :layout => 'touch'
  end

  def create

    patient = Patient.find(params[:order_entry][:patient_id])
    (params[:order_entry][:categories] || []).each do |category|

      
      if category.downcase == "admission"
        OrderEntry.create(:patient_id => patient.id,:order_date => DateTime.current,
                          :quantity => params[:order_entry][:admission][:stay][:quantity],
                          :service_id => Service.find_by_name(params[:order_entry][:admission][:stay][:service]).id,
                          :location =>params[:order_entry][:location],
                          :service_point =>params[:order_entry][:location_name],
                          :cashier => params[:creator])
  end

=begin

      if %w[admission consultation].include?(category.downcase)
        if patient.person.is_child?
          service = "#{category.downcase.strip} (paediatric)"
          OrderEntry.create(:patient_id => patient.id,:order_date => DateTime.current, :quantity => 1,
                            :service_offered => service,:location =>params[:order_entry][:location],
                            :service_point =>params[:order_entry][:location_name],:cashier => params[:creator])
        else
          service = "#{category.downcase.strip} (adult)"
          OrderEntry.create(:patient_id => patient.id,:order_date => DateTime.current, :quantity => 1,
                            :service_offered => service, :location =>params[:order_entry][:location],
                            :service_point =>params[:order_entry][:location_name], :cashier => params[:creator])
        end
      else
=end
      if (params[:order_entry][category.downcase.gsub(' ','_')] || []).is_a?(Array)
        (params[:order_entry][category.downcase.gsub(' ','_')] || []).each do |item|
          next if (item.blank? || item == 'Others')
          o= OrderEntry.create(:patient_id => patient.id,:order_date => DateTime.current, :quantity => 1,
                            :service_id => Service.find_by_name(item).id, :location =>params[:order_entry][:location],
                            :service_point =>params[:order_entry][:location_name],
                            :cashier => params[:creator])
        end
      elsif(params[:order_entry][category.downcase.gsub(' ','_')] || []).is_a?(Hash)
        (params[:order_entry][category.downcase.gsub(' ','_')] || []).each do |order,item|
          next if (item[:service].blank? || item[:service] == 'Others')

          qty = (item[:quantity].blank? ? 1 : item[:quantity].to_f) * (item[:dose].blank? ? 1 : item[:dose].to_f)
          qty = qty*(item[:frequency].blank? ? 1 : frequencies(item[:frequency]))*(item[:duration].blank? ? 1 : item[:duration].to_f)
          OrderEntry.create(:patient_id => patient.id,:order_date => DateTime.current, :quantity => qty.ceil,
                            :service_id => Service.find_by_name(item[:service]).id , :location =>params[:order_entry][:location],
                            :service_point =>params[:order_entry][:location_name],
                            :cashier => params[:creator])
        end
      end


      next if params[:order_entry][:panels].blank?

      (params[:order_entry][:panels][category.downcase.gsub(' ','_')] || []).each do |panel|
        service_panel = ServicePanel.find_by_name(panel)

        next if service_panel.blank?
        (service_panel.service_panel_details ||[]).each do |item|
          OrderEntry.create(:patient_id => patient.id,:order_date => DateTime.current, :quantity => item.quantity,
                            :service_id => item.service_id, :location =>params[:order_entry][:location],
                            :service_point =>params[:order_entry][:location_name],
                            :cashier => params[:creator])
        end
      end
      #end
    end

    redirect_to patient
  end

  def edit
    render :layout => 'touch'
  end

  def update

  end

  def destroy

    entry = OrderEntry.where(order_entry_id: params[:id]).first

    redirect_to entry.patient
  end

  def void
    entries = OrderEntry.where(order_entry_id: params[:void_ids].split(','))
    (entries || []).each do |entry|
      entry.void(params[:void_reason], current_user.id)
    end
    redirect_to "/patients/#{params[:patient_id]}"
  end
end
