class ServicesController < ApplicationController
  def index
    @services = Service.all
  end

  def show
    @service = Service.find(params[:id])
  end

  def new
    render :layout => 'touch'
  end

  def create
    @new_service = Service.create(service_params)
    (params[:service_price] || []).each do |type, price|
      service_price = ServicePrice.new()
      service_price.price_type = type
      service_price.service_id = @new_service.id
      service_price.price = price[:price]
      service_price.creator = params[:service][:creator]
      service_price.updated_by = params[:service][:creator]
      service_price.save
    end
    redirect_to @new_service
  end

  def update
    @new_service = Service.find(params[:id])
    @new_service.update(service_params)
    (params[:service_price] || []).each do |type, price|
      service_price = ServicePrice.new()
      service_price.price_type = type
      service_price.service_id = @new_service.id
      service_price.price = price[:price]
      service_price.creator = params[:creator]
      service_price.updated_by = params[:creator]
      service_price.save
    end
    redirect_to @new_service
  end

  def edit
    @service = Service.find(params[:id])
    render :layout => 'touch'
  end

  def destroy

  end

  def suggestions
    type = ServiceType.find_by_name(params[:category])
    services = Service.select(:name).where('service_type_id = ? and name like (?)',
                                           type.id, "%#{params[:search_string]}%" ).map do |v|
      "<li value=\"#{v.name}\">#{v.name}</li>"
    end

    render :body => services.join('') and return
  end

  private
  def service_params
    params.require(:service).permit(:category,:name, :creator)
  end
end
