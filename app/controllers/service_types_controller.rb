class ServiceTypesController < ApplicationController
  def index
    @categories = ServiceType.all
  end

  def show
    @category = ServiceType.find(params[:id])
  end

  def new
    render :layout => 'touch'
  end

  def create

    new_service_type = ServiceType.where(name: params[:service_type][:name]).first_or_initialize
    new_service_type.creator = params[:service_type][:creator]
    new_service_type.save
    redirect_to "/service_types" and return
  end

  def update
    edit_service_type = ServiceType.find(params[:id])
    edit_service_type.name = params[:service_type][:name]
    edit_service_type.save
    redirect_to "/service_types" and return
  end

  def edit
    @service_type = ServiceType.find(params[:id])
    render :layout => 'touch'
  end

  def destroy

  end

end
