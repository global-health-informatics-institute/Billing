class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def new
    @user = User.new
    render layout: 'touch'
  end

  def create
    existing_user = User.where(username: params[:user][:username]).first

    if existing_user.present?
      flash[:notice] = 'Username already in use'
      redirect_to "/users/new" and return
    end

    if params[:password] != params[:confirm_password]
      flash[:notice] = 'Password Mismatch'
      redirect_to action: 'new' and return
    end

    person = Person.create
    person.names.create(given_name: params[:user][:given_name], family_name: params[:user][:family_name])

    @user = User.create(username: params[:user][:username], plain_password: params[:password],
                        creator: params[:creator], person_id: person.id)

    @user.user_roles.create(role: Role.find_by_role(params[:user_role][:role_id])&.role)

    if @user.errors.blank?
      flash[:notice] = 'User was successfully created.'
      redirect_to "/users"
    else
      flash[:notice] = 'Oops! User was not created!'
      redirect_to "/users/new"
    end
  end

  
  
  
  def edit
    @user = User.find(params[:id]) # Ensure it loads the correct user instead of always current_user
    @field = (params[:attribute] == 'name' ? 'NAME' : 'PASSWORD')
    render layout: 'touch'
  end

  def update
    @user = User.find_by(user_id: params[:user_id])
    redirect_to "/" and return if @user.blank?
  
    puts "Updating user #{@user.id}" # Log the user we're updating
    puts "Params: #{params.inspect}" # Log the form parameters
  
    case params[:fields]
    when 'NAME'
      person_name = @user.person.names.order("date_created DESC").first
      
      if person_name.present?
        person_name.update(given_name: params[:given_name], family_name: params[:family_name])
      else
        person_name = PersonName.create(given_name: params[:given_name], family_name: params[:family_name], person_id: @user.person_id)
      end

      if person_name.persisted?
        flash[:notice] = 'User details successfully updated'
      else
        flash[:error] = 'User details could not be updated'
        puts "Errors: #{person_name.errors.full_messages}" # Log errors if name update fails
      end

      # Update username if provided along with NAME update
      if params[:username].present?
        if User.exists?(username: params[:username])
          flash[:error] = 'Username already taken'
        elsif @user.update(username: params[:username])
          flash[:notice] += ' and Username successfully updated'
        else
          flash[:error] = 'Failed to update username'
          puts "Errors: #{@user.errors.full_messages}" # Log errors if username update fails
        end
      end
  
    when 'PASSWORD'
      if params[:password] == params[:confirm_password]
        @user.plain_password = params[:password]
        if @user.save
          flash[:notice] = 'Password successfully updated'
        else
          flash[:error] = 'Failed to update password'
          puts "Errors: #{@user.errors.full_messages}" # Log errors if password update fails
        end
      else
        flash[:error] = 'User passwords did not match'
      end
  
    when 'USERNAME'
      if params[:username].present?
        if User.exists?(username: params[:username])
          flash[:error] = 'Username already taken'
        elsif @user.update(username: params[:username])
          flash[:notice] = 'Username successfully updated'
        else
          flash[:error] = 'Failed to update username'
          puts "Errors: #{@user.errors.full_messages}" # Log errors if username update fails
        end
      else
        flash[:error] = 'Username cannot be blank'
      end
    end
    
    redirect_to user_path(@user.reload) # Ensure updated details are loaded
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

  def show
  @user = User.find_by(user_id: params[:id])

  if @user.nil?
    flash[:error] = "User not found"
    redirect_to users_path and return
  end
end

  def roles
    role_conditions = ["role LIKE ?", "%#{params[:value]}%"]
    roles = Role.where(role_conditions)
    roles = roles.map do |r|
      "<li value='#{r.role}'>#{r.role.gsub('_', ' ').capitalize}</li>"
    end
    render body: roles.join('')
  end
end