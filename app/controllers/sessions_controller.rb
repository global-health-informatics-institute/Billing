class SessionsController < ApplicationController
  def login
    render :layout => 'touch'
  end

  def create_session

    state = User.authenticate(params['login'],params['password'])

    if state
      user = User.find_by_username(params['login'])
      User.current = user
      session[:user_id] = user.id
      @current_user = user
      flash[:errors] = nil
      redirect_to "/location" and return
    else
      flash[:errors] = "Invalid user credentials"
      redirect_to '/login' and return
    end

  end

  def location
    render :layout => 'touch'
  end

  def add_location

    location = Location.find(params[:location]) rescue nil
    location ||= Location.find_by_name(params[:location]) rescue nil

    if location.blank?
      flash[:error] = "Invalid workstation location"
      redirect_to "/location"
    else
      session[:location] = location.id
      redirect_to root_path
    end

  end

  def destroy
    session[:user_id] = nil
    @current_user = nil
    User.current = nil
    redirect_to '/login' and return
  end
end
