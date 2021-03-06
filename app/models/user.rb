class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :validatable, :lockable

  attr_accessor :login

  has_many :pipelines

  has_and_belongs_to_many :publications


  def full_name?
    not (first_name.blank? and last_name.blank?)
  end


  def full_name
    [first_name, last_name].join ' '
  end


  def admin!
    self.admin = true
  end


  def self.guest
    gid = SecureRandom.uuid
    username = "guest-#{gid}"
    new guest: true, username: username, email: "#{username}@example.com", password: gid
  end


  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    if login
      where(conditions).where(['lower(username) = :value OR lower(email) = :value', { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

end
