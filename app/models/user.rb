class User < ApplicationRecord
  include User::NetworkValidatable
  include User::Omniauthable

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

  before_save :update_departments_based_on_geo_access, if: :will_save_change_to_geo_access_id?

  # Discarded users cannot authenticate (See https://github.com/jhawthorn/discard?tab=readme-ov-file#working-with-devise)
  def active_for_authentication?
    super && !discarded?
  end

  def inactive_message
    discarded? ? :discarded_account : super
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

  def networks_for_establishment(establishment)
    active_networks.reject do |network|
      network.name == "CODEFI" && departments.exclude?(establishment.department)
    end
  end

  private

  def update_departments_based_on_geo_access
    self.departments = if geo_access.name.downcase == "france entière"
                         Department.all
                       else
                         geo_access.departments
                       end
  end
end
