class MedicalSchemeController < ApplicationController
  def show

  end

  def create
    new_scheme = MedicalScheme.new()
    new_scheme.name = params[:medical_scheme][:name]
    new_scheme.medical_scheme_provider = MedicalSchemeProvider.find(params[:medical_scheme][:medical_scheme_provider_id])
    new_scheme.creator = params[:medical_scheme][:creator]
    new_scheme.save

    redirect_to "/medical_scheme_providers/#{new_scheme.medical_scheme_provider.id}"
  end

  def new
    @id = params[:medical_scheme_provider_id]
    render :layout => 'touch'
  end

  def edit

  end

  def update

  end

  def destroy

  end

  private
  def medical_scheme_params
    params.require(:medical_scheme).permit(:name, :medical_scheme_provider, :creator)
  end
end
