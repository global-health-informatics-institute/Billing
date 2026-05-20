class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate, :except => %w[login create_session]
  helper_method :current_user, :current_location
  rescue_from StandardError, with: :render_600

  def print_and_redirect(print_url, redirect_url, message = "Printing label ...", show_next_button = false, patient_id = nil)
    #Function handles redirects when printing labels
    @print_url = print_url
    @redirect_url = redirect_url
    @message = message
    @show_next_button = show_next_button
    render template: "application/print_and_redirect", layout: false
  end

  def just_redirect(redirect_url)
    flash[:notice] = "Transaction added but not printing labels"
    redirect_to redirect_url
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
    return YAML.load_file("#{Rails.root}/config/application.yml", aliases: true)['facility_code']
  end

   def render_500(exception = nil)
     error_message = exception ? exception.message : "Unknown error"

     # Log full error details for debugging
     logger.error("ERROR: #{error_message}")
     logger.error(exception.backtrace.join("\n")) if exception

     # Render a simple 500 page with user-friendly error message
     render html: <<-HTML.html_safe, status: 500
       <!DOCTYPE html>
       <html>
       <head>
           <title>500 - Error</title>
           <style>
               body {
                   text-align: center;
                   font-family: Arial, sans-serif;
                   background-color: #f8d7da;
                   color: #721c24;
                   display: flex;
                   flex-direction: column;
                   justify-content: center;
                   align-items: center;
                   height: 100vh;
                   margin: 0;
               }
               h1 {
                   font-size: 100px;
                   margin-bottom: 20px;
               }
               p {
                   font-size: 24px;
               }
               .error-message {
                   font-size: 18px;
                   background: #fff3cd;
                   color: #856404;
                   padding: 10px;
                   border-radius: 5px;
                   margin-top: 20px;
                   max-width: 80%;
                   word-wrap: break-word;
               }
           </style>
       </head>
       <body>
           <h1>500</h1>
           <p>Please contact support</p>
           <p>Something went wrong. We are working on it.</p>
           <div class="error-message">#{error_message}</div>
           <%= link_to 'Go to Home', root_path, class: 'btn btn-primary', style: 'margin-top: 20px;' %>
       </body>
       </html>
     HTML
   end

   def render_600(exception = nil)
     error_message = exception ? exception.message : "Unknown error"

     # Log full error details for debugging
     logger.error("ERROR: #{error_message}")
     logger.error(exception.backtrace.join("\n")) if exception

     # Render a simple 600 page with user-friendly error message
     render html: <<-HTML.html_safe, status: 600
       <!DOCTYPE html>
       <html>
       <head>
           <title>600 - Error</title>
           <style>
               body {
                   text-align: center;
                   font-family: Arial, sans-serif;
                   background-color: #f8d7da;
                   color: #721c24;
                   display: flex;
                   flex-direction: column;
                   justify-content: center;
                   align-items: center;
                   height: 100vh;
                   margin: 0;
               }
               h1 {
                   font-size: 100px;
                   margin-bottom: 20px;
               }
               p {
                   font-size: 24px;
               }
               .error-message {
                   font-size: 18px;
                   background: #fff3cd;
                   color: #856404;
                   padding: 10px;
                   border-radius: 5px;
                   margin-top: 20px;
                   max-width: 80%;
                   word-wrap: break-word;
               }
           </style>
       </head>
       <body>
           <h1>600</h1>
           <p>Please contact support</p>
           <p>Something went wrong. We are working on it.</p>
           <div class="error-message">#{error_message}</div>
       </body>
       </html>
     HTML
   end
end
