class EstablishmentTracking < ApplicationRecord
  include AASM

  # EstablishmentTracking can be soft deleted
  include Discard::Model

  belongs_to :creator, class_name: 'User'
  belongs_to :establishment

  has_many :tracking_referents, dependent: :destroy
  has_many :referents, through: :tracking_referents, source: :user

  has_many :tracking_participants, dependent: :destroy
  has_many :participants, through: :tracking_participants, source: :user

  has_many :establishment_tracking_labels, dependent: :destroy
  has_many :tracking_labels, through: :establishment_tracking_labels

  has_many :establishment_tracking_actions, dependent: :destroy
  has_many :actions, through: :establishment_tracking_actions

  has_many :summaries, dependent: :destroy
  has_many :comments, dependent: :destroy

  belongs_to :size, optional: true
  belongs_to :criticality, optional: true

  has_and_belongs_to_many :sectors, join_table: :establishment_tracking_sectors

  before_create :set_modified_at
  before_save :update_modified_at_if_criticality_changed

  validates :referents, presence: true

  validate :single_active_tracking, on: :create

  scope :in_progress, -> { where(state: 'in_progress') }
  scope :completed, -> { where(state: 'completed') }
  scope :cancelled, -> { where(state: 'cancelled') }

  scope :with_user_as_referent_or_participant, ->(user) {
    joins(:tracking_participants, :tracking_referents)
      .where('tracking_participants.user_id = :user_id OR tracking_referents.user_id = :user_id', user_id: user.id).distinct
  }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "creator_id", "end_date", "establishment_id", "id", "id_value", "start_date", "state", "criticality_id", "size_id", "updated_at", "modified_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["comments", "creator", "establishment", "establishment_tracking_labels", "participants", "referents", "summaries", "tracking_labels", "tracking_participants", "tracking_referents", "sectors"]
  end

  aasm column: 'state' do
    state :in_progress, initial: true
    state :completed
    state :under_surveillance

    event :complete do
      before do
        self.end_date = Date.today
      end
      transitions from: [:in_progress, :under_surveillance, :completed], to: :completed
    end

    event :start_surveillance do
      transitions from: [:in_progress, :completed, :under_surveillance], to: :under_surveillance
    end

    event :resume do
      transitions from: [:completed, :under_surveillance, :in_progress], to: :in_progress
    end
  end

  private

  def single_active_tracking
    if establishment.establishment_trackings.where(state: ['in_progress', 'under_surveillance']).exists?
      errors.add(:base, 'Un accompagnement "en cours" ou "sous surveillance" existe déjà pour cet établissement.')
    end
  end

  def set_modified_at
    self.modified_at ||= Date.current
  end

  def update_modified_at_if_criticality_changed
    self.modified_at = Date.current if criticality_id_changed?
  end
end