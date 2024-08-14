class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  belongs_to :entity, optional: false
  belongs_to :segment, optional: false
  belongs_to :geo_access, optional: false
  has_and_belongs_to_many :roles

  has_many :created_trackings, class_name: 'EstablishmentTracking', foreign_key: 'creator_id'
  has_many :tracking_participants
  has_many :participated_trackings, through: :tracking_participants, source: :establishment_tracking

  validates :email, presence: true, uniqueness: true
  validates :level, presence: true

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

  def update_roles(auth)
    puts "auth credentials"
    puts auth.credentials
    roles = extract_roles_from_token(auth.credentials.token)
    puts roles.inspect
    self.roles = roles.map { |role_name| Role.find_or_create_by(name: role_name) }
    save!
  end

  def full_name
    "#{first_name} #{last_name}"
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
