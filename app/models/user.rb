class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  # Users can be soft deleted
  include Discard::Model

  belongs_to :entity, optional: false
  belongs_to :segment, optional: false
  belongs_to :geo_access, optional: false
  has_many :network_memberships, dependent: :destroy
  has_many :networks, through: :network_memberships

  has_and_belongs_to_many :roles

  has_many :created_trackings, class_name: "EstablishmentTracking", foreign_key: "creator_id", dependent: :nullify

  has_many :tracking_referents, dependent: :destroy
  has_many :referent_trackings, through: :tracking_referents, source: :establishment_tracking

  has_many :tracking_participants, dependent: :destroy
  has_many :participated_trackings, through: :tracking_participants, source: :establishment_tracking

  has_many :user_departments, dependent: :destroy
  has_many :departments, through: :user_departments

  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name), allow_nil: true }
  validates :email, presence: true, uniqueness: true
  validates :level, presence: true
  validate :validate_network_memberships

  before_save :update_departments_based_on_geo_access, if: :will_save_change_to_geo_access_id?

  # Discarded users cannot authenticate (See https://github.com/jhawthorn/discard?tab=readme-ov-file#working-with-devise)
  def active_for_authentication?
    super && !discarded?
  end

  def inactive_message
    discarded? ? :discarded_account : super
  end

  def self.from_omniauth(auth)
    Rails.logger.debug { "auth info: #{auth.inspect}" }

    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.id_token = auth.credentials.id_token # store the ID token (used by logout to destroy keykloak's session)
    end
    user.update_roles(auth)
    user
  end

  def update_roles(auth)
    Rails.logger.debug "auth credentials"
    Rails.logger.debug auth.credentials
    roles = extract_roles_from_token(auth.credentials.token)
    Rails.logger.debug roles.inspect
    self.roles = roles.map { |role_name| Role.find_or_create_by(name: role_name) }
    save!
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    "#{full_name} (#{entity.name})"
  end

  def non_codefi_network
    networks.where.not(name: "CODEFI").first
  end

  def active_networks
    networks.where(active: true).sort_by { |network| network.name == "CODEFI" ? 0 : 1 }
  end

  private

  def extract_roles_from_token(token)
    decoded_token = JWT.decode(token, nil, false)
    resource_access = decoded_token.first["resource_access"]
    return [] unless resource_access && resource_access["signauxfaibles"]

    resource_access["signauxfaibles"]["roles"]
  rescue StandardError
    []
  end

  def update_departments_based_on_geo_access
    self.departments = if geo_access.name.downcase == "france entière"
                         Department.all
                       else
                         geo_access.departments
                       end
  end

  def validate_network_memberships
    validate_network_count
    validate_network_combinations if networks.any?
  end

  def validate_network_count
    return if networks.size.between?(1, 2)

    errors.add(:networks, "Un utilisateur ne peut appartenir qu'à un ou deux réseaux")
  end

  def validate_network_combinations
    case networks.size
    when 1
      validate_single_network
    when 2
      validate_dual_networks
    end
  end

  def validate_single_network
    return unless networks.first.name == "CODEFI"

    errors.add(:networks, "Un utilisateur ne peut pas appartenir uniquement au réseau CODEFI")
  end

  def validate_dual_networks
    return if networks.any? { |network| network.name == "CODEFI" }

    errors.add(:networks, "Si un utilisateur appartient à deux réseaux, l'un d'eux doit être CODEFI")
  end
end
