require 'digest/sha1'
require 'digest/sha2'

class User < ActiveRecord::Base
  #establish_connection Registration

    self.table_name = "users"
    self.primary_key = "user_id"
    include Openmrs

    before_save :before_create

    attr :plain_password
    cattr_accessor :current_user
    attr_accessor :plain_password
    attr_accessor :password_salt
    attr_accessor :encrypted_password
    attr_accessor :login


    belongs_to :person, -> {where voided: false}, :foreign_key => :person_id
    has_many :user_properties, :foreign_key => :user_id
    has_many :user_roles, :foreign_key => :user_id
    has_many :names,-> { where "voided =  false"}, :class_name => 'PersonName', :foreign_key => :person_id

    def set_password
      # We expect that the default OpenMRS interface is used to create users
      #self.password = self.encrypted_password
      self.password = encrypt(self.plain_password, self.salt) if self.plain_password
    end

    #has_one :activities_property, :class_name => 'UserProperty', :foreign_key => :user_id, :conditions => ['property = ?', 'Activities']

    def self.authenticate(username, password)
      user = User.where(username: username).first
      if !user.blank?
        user.valid_password?(password) ? user : nil
      end
    end

    def valid_password?(password)
      return false if encrypted_password.blank?
      is_valid = Digest::SHA1.hexdigest("#{password}#{salt}") == encrypted_password	|| encrypt(password, salt) == encrypted_password || Digest::SHA512.hexdigest("#{password}#{salt}") == encrypted_password
    end

    def first_name
      self.person.names.first.given_name rescue ''
    end

    def last_name
      self.person.names.first.family_name rescue ''
    end

    def name
      name = self.person.names.first
      "#{name.given_name} #{name.family_name}"
    end

    def try_to_login
      User.authenticate(self.username, self.password)
    end

    def password_salt
      salt
    end

    # overwrite this method so that we call the encryptor class properly
    def encrypt_password
      unless @password.blank?
        self.password_salt = salt
        self.encrypted_password = encrypt(@password, salt)
      end
    end

    def password
      # We expect that the default OpenMRS interface is used to create users
      #self.password = encrypt(self.plain_password, self.salt) if self.plain_password

      self[:password]
    end

    def password_digest(pwd)
      encrypt(pwd, salt)
    end

    def encrypted_password
      self.password
    end


    # Encrypts plain data with the salt.
    # Digest::SHA1.hexdigest("#{plain}#{salt}") would be equivalent to
    # MySQL SHA1 method, however OpenMRS uses a custom hex encoding which drops
    # Leading zeroes
    def encrypt(plain, salt)
      encoding = ""
      digest = Digest::SHA1.digest("#{plain}#{salt}")
      (0..digest.size-1).each{|i| encoding << digest[i].to_s() }
      encoding
    end

    def before_create
      super
      self.salt = User.random_string(10) if !self.salt?
      self.password = User.encrypt(plain_password, salt) if plain_password
    end

    def self.random_string(len)
      #generat a random password consisting of strings and digits
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      newpass = ""
      1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
      return newpass
    end

    def self.encrypt(password,salt)
      Digest::SHA1.hexdigest(password+salt)
    end

    def is_admin?
      roles = self.user_roles.collect{|c| c.role}
      roles.any? {|x| ["Informatics Manager","Program Manager", "Superuser", "Superuser,Superuser,", "System Developer"].include? x}
    end

    def role
      self.user_roles.first.role rescue ''
    end

    def self.current
      Thread.current[:user]
    end

    def self.current=(user)
      Thread.current[:user] = user
    end
=begin
    def activities
      a = activities_property
      return [] unless a
      a.property_value.split(',')
    end

    # Should we eventually check that they cannot assign an activity they don't
    # have a corresponding privilege for?
    def activities=(arr)
      prop = activities_property || UserProperty.new
      prop.property = 'Activities'
      prop.property_value = arr.join(',')
      prop.user_id = self.id
      prop.save
    end
=end

end
