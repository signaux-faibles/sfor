class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  has_many :establishment_followers
  has_many :establishments, through: :establishment_followers
  has_and_belongs_to_many :roles

  validates :email, presence: true, uniqueness: true

  def self.from_omniauth(auth)
    puts "auth info: #{auth.inspect}"

    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.id_token = auth.credentials.id_token # store the ID token (used by logout to destroy keykloak's session)
    end
    user.update_roles(auth)
    user
  end

  def establishments_followed
    EstablishmentFollower.where(user: self).includes(:establishment)
  end

  def update_roles(auth)
    puts "auth credentials"
    puts auth.credentials
    roles = extract_roles_from_token(auth.credentials.token)
    puts roles.inspect
    self.roles = roles.map { |role_name| Role.find_or_create_by(name: role_name) }
    save!
  end

  private

  def extract_roles_from_token(token)
    decoded_token = JWT.decode(token, nil, false)
    resource_access = decoded_token.first['resource_access']
    return [] unless resource_access && resource_access['signauxfaibles']

    resource_access['signauxfaibles']['roles']
  rescue
    []
  end
end
