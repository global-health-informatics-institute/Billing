class ServicesController < ApplicationController
  def index
    @services = Service.all
  end

  def show
    @service = Service.find(params[:id])
    @service_sets = @service.service_sets
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
  end

  def new
    render :layout => 'touch'
  end

  def create
    attrs = service_params.except(:category, :demographics)
    attrs = attrs.merge(service_type_id: params[:service][:category]) if params[:service] && params[:service][:category].present?
    creator_id = (params.dig(:service, :creator) || params[:creator] || current_user&.user_id)
    set_ids = demographics_to_set_ids(params[:service][:demographics])
    begin
      ActiveRecord::Base.transaction do
        @new_service = Service.create!(attrs)
        (params[:service_price] || {}).each do |type, price|
          @new_service.service_prices.create!(
            price_type: type,
            price: price[:price],
            creator: creator_id,
            updated_by: creator_id
          )
        end
        (set_ids || []).each do |set_id|
          @new_service.service_set_maps.create!(service_set_id: set_id, creator: creator_id)
        end
      end
      flash[:success] = 'Service saved successfully'
      redirect_to @new_service
    rescue ActiveRecord::RecordInvalid => e
      @new_service = e.record.is_a?(Service) ? e.record : Service.new(attrs)
      flash.now[:errors] = @new_service.errors.full_messages.join(', ')
      render :new, layout: 'touch'
    rescue StandardError => e
      flash.now[:errors] = "Could not save service: #{e.message}"
      @new_service ||= Service.new(attrs)
      render :new, layout: 'touch'
    end
  end

  def update
    @new_service = Service.find(params[:id])
    attrs = service_params.except(:category, :demographics)
    attrs = attrs.merge(service_type_id: params[:service][:category]) if params[:service] && params[:service][:category].present?
    creator_id = (params.dig(:service, :creator) || params[:creator] || current_user&.user_id)
    set_ids = demographics_to_set_ids(params[:service][:demographics])
    begin
      ActiveRecord::Base.transaction do
        @new_service.update!(attrs)
        (params[:service_price] || {}).each do |type, price|
          @new_service.service_prices.create!(
            price_type: type,
            price: price[:price],
            creator: creator_id,
            updated_by: creator_id
          )
        end
        @new_service.service_set_maps.where.not(service_set_id: (set_ids || [])).each do |map|
          map.update(voided: true, voided_by: creator_id, voided_date: Date.current)
        end
        (set_ids || []).each do |set_id|
          unless @new_service.service_set_maps.exists?(service_set_id: set_id)
            @new_service.service_set_maps.create!(service_set_id: set_id, creator: creator_id)
          end
        end
      end
      flash[:success] = 'Service updated successfully'
      redirect_to @new_service
    rescue ActiveRecord::RecordInvalid => e
      @new_service = e.record.is_a?(Service) ? e.record : @new_service
      flash.now[:errors] = @new_service.errors.full_messages.join(', ')
      render :edit, layout: 'touch'
    rescue StandardError => e
      flash.now[:errors] = "Could not update service: #{e.message}"
      render :edit, layout: 'touch'
    end
  end

  def edit
    @service = Service.find(params[:id])
    render :layout => 'touch'
  end

  def destroy

  end

  def suggestions
    type = ServiceType.find_by_name(params[:category])
    service_ids = if params[:demographic].present?
      set = ServiceSet.find_by(name: params[:demographic])
      set ? set.services.pluck(:service_id) : []
    else
      Service.where(service_type_id: type.id).pluck(:service_id)
    end

    services = Service.select(:name).where('service_id IN (?) and name like (?)', service_ids, "%#{params[:search_string]}%").map do |v|
      "<li value=\"#{v.name}\">#{v.name}</li>"
    end

    render :body => services.join('') and return
  end

  private
  def service_params
    params.require(:service).permit(:category, :name, :creator, :demographics)
  end

  def demographics_to_set_ids(demo_value)
    case demo_value
    when 'child'
      [ServiceSet.find_by(name: 'under_5')&.service_set_id].compact
    when 'male'
      [ServiceSet.find_by(name: 'male')&.service_set_id].compact
    when 'female'
      [ServiceSet.find_by(name: 'female')&.service_set_id].compact
    when 'male_female'
      [ServiceSet.find_by(name: 'male')&.service_set_id, ServiceSet.find_by(name: 'female')&.service_set_id].compact
    when 'all'
      [ServiceSet.find_by(name: 'under_5')&.service_set_id, ServiceSet.find_by(name: 'male')&.service_set_id, ServiceSet.find_by(name: 'female')&.service_set_id].compact
    else
      []
    end
  end
end
