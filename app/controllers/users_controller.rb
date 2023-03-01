class UsersController < ApplicationController
  def index
    @users = User.all
  end
  def new
    @user = User.new
    render :layout => 'touch'
  end
  def create
    existing_user = User.where(username: params[:user][:username]) rescue nil

    if !existing_user.blank?
      flash[:notice] = 'Username already in use'
      redirect_to "/users/new" and return
    end
    if (params[:password] != params[:confirm_password])
      flash[:notice] = 'Password Mismatch'
      redirect_to :action => 'new' and return
    end

    person = Person.create()
    person.names.create(given_name: params[:user][:given_name], family_name: params[:user][:family_name])

    @user = User.create(username: params[:user][:username], plain_password: params[:password],
                        creator: params[:creator], person_id: person.id)

    @user.user_roles.create(role: Role.find_by_role( params[:user_role][:role_id]).role)

    if @user.errors.blank?
      flash[:notice] = 'User was successfully created.'
    else
      flash[:notice] = 'Oops! User was not created!.'
      redirect_to "/users/new" and return
    end
    redirect_to "/users"
  end
  def edit
    @field = (params[:attribute] == 'name' ? 'NAME' : 'PASSWORD')
    render :layout => 'touch'
  end
  def update

    @user = User.find(params[:user_id])
    redirect_to "/" and return if @user.blank?

    case params[:fields]
    when 'NAME'
      person_name = PersonName.create(given_name: params[:given_name], family_name: params[:family_name] , person_id: @user.person_id)

      if person_name.blank? || !person_name.errors.blank?
        flash[:error] = 'User details could not be updated'
      else
        flash[:notice] = 'User details successfully updated'
      end

    when 'PASSWORD'

      if params[:password] == params[:confirm_password]
        @user.plain_password = params[:password]
        @user.save
      else
        flash[:error] = 'User passwords did not match'
      end
    end

    redirect_to @user
  end
  def show
    @user = User.find_by_user_id(params[:id])
  end

  def destroy

    result = User.where(user_id: params[:id]).update_all(retired: true, retire_reason: params[:user][:void_reason],
                                                         date_retired: DateTime.current,
                                                         retired_by: params[:user][:creator])

    if result
      flash[:notice] = 'User account successfully deactivated'
    else
      flash[:error] = 'User details could not be deactivated'
    end

    redirect_to "/users"
  end

  def roles
    role_conditions = ["role LIKE (?)", "%#{params[:value]}%"]
    roles = Role.where( role_conditions)
    roles = roles.map do |r|
      "<li value='#{r.role}'>#{r.role.gsub('_',' ').capitalize}</li>"
    end
    render :body => roles.join('') and return
  end
end
