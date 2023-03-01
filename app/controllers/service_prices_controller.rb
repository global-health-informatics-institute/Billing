class ServicePricesController < ApplicationController
  def new
    @name = Service.find(params[:service_id]).name
    render :layout => 'touch'
  end
  def create
    service_price = ServicePrice.where(service_id: params[:service_price][:service_id],
                                       price_type: params[:service_price][:price_type]).first_or_initialize
    service_price.price = params[:service_price][:price]
    service_price.creator = params[:service_price][:creator] if service_price.creator.blank?
    service_price.updated_by = params[:service_price][:creator]
    service_price.save

    redirect_to "/services/#{params[:service_id]}"
  end

  private
  def service_price_params
    params.require(:service_price).permit(:service_id, :price_type,:price, :creator)
  end
end
