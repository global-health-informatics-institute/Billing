class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate, :except => %w[login create_session]
  helper_method :current_user, :current_location

  def print_and_redirect(print_url, redirect_url, message = "Printing Patient ID...", show_next_button = false, patient_id = nil)
    #Function handles redirects when printing labels
    @print_url = print_url
    @redirect_url = redirect_url
    @message = message
    @show_next_button = show_next_button
    render :layout => false
  end
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  def current_location
    @current_location ||= Location.find(session[:location]) if session[:location]
  end

  def authenticate
    if current_user.blank?
      redirect_to "/login" and return
    else
      return true
    end
  end

  def frequencies(frequency)
    frequencies = {'BID' => 2, 'EOD' => 0.5, 'OD' => 1, 'TDS' => 3, 'q.h' => 24, 'q.2.h' => 12, 'q.3.h' => 8,
                   'q.4.h' => 6, 'q.d.s' => 4}
    return frequencies[frequency]
  end

  private
  def name_of_app
    return "Billing"
  end

  def facility_code
    return YAML.load_file("#{Rails.root}/config/application.yml")['facility_code']
  end

end
