class MedicalSchemeProvidersController < ApplicationController
  def index
    @insurers = MedicalSchemeProvider.all
  end
  def show
    @insurer = MedicalSchemeProvider.find(params[:id])
    @schemes = @insurer.medical_schemes
  end
  def new
    render :layout => 'touch'
  end
  def create

    @new_insurer = MedicalSchemeProvider.create(medical_scheme_provider_params)
    redirect_to @new_insurer
  end
  def edit

  end
  def update

  end
  def destroy

  end

  def suggestions
    company = MedicalSchemeProvider.find_by_company_name(params[:name]).id
    schemes = MedicalScheme.where("medical_scheme_provider = ? AND name like (?)",
                                  company, "%#{params[:search_string]}%").map do |v|
      "<li value=\"#{v.medical_scheme_id}\">#{v.name}</li>"
    end

    render :text => schemes.join('') and return
  end

  private

  def medical_scheme_provider_params
    params.require(:medical_scheme_provider).permit(:company_name, :company_address,:phone_number_1,
                                                    :phone_number_2,:email_address,:creator)
  end
end
