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
  has_many :user_actions, through: :establishment_tracking_actions

  has_many :summaries, dependent: :destroy
  has_many :comments, dependent: :destroy

  belongs_to :size, optional: true
  belongs_to :criticality, optional: true

  has_and_belongs_to_many :sectors, join_table: :establishment_tracking_sectors
  has_and_belongs_to_many :difficulties
  has_and_belongs_to_many :codefi_redirects

  before_save :update_modified_at_if_criticality_changed
  before_create :set_modified_at
  after_update :add_codefi_redirect_user_action

  attr_accessor :skip_update_modified_at

  validates :referents, presence: true

  validate :single_active_tracking, if: -> { state.in?(['in_progress', 'under_surveillance']) }

  scope :in_progress, -> { where(state: 'in_progress') }
  scope :completed, -> { where(state: 'completed') }
  scope :under_surveillance, -> { where(state: 'under_surveillance') }

  scope :with_user_as_referent_or_participant, ->(user) {
    joins(:tracking_participants, :tracking_referents)
      .where('tracking_participants.user_id = :user_id OR tracking_referents.user_id = :user_id', user_id: user.id).distinct
  }

  scope :by_network_participants, ->(network_ids) {
    left_joins(tracking_participants: { user: { network_memberships: :network } })
      .where.not(networks: { name: 'CODEFI' })
      .where(networks: { id: network_ids })
  }

  scope :by_network_referents, ->(network_ids) {
    left_joins(tracking_referents: { user: { network_memberships: :network } })
      .where.not(networks: { name: 'CODEFI' })
      .where(networks: { id: network_ids })
  }

  scope :by_network, ->(network_ids) {
    where(id: by_network_participants(network_ids))
      .or(where(id: by_network_referents(network_ids)))
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
    if establishment.establishment_trackings
                    .where(state: ['in_progress', 'under_surveillance'])
                    .where.not(id: id) # Exclude the current record if updating
                    .exists?
      errors.add(:state, 'Un accompagnement "en cours" ou "sous surveillance" existe déjà pour cet établissement.')
    end
  end

  def set_modified_at
    self.modified_at = self.modified_at.presence || Date.current
  end

  def update_modified_at_if_criticality_changed
    return if @skip_modified_at_update

    self.modified_at = Date.current if criticality_id_changed?
  end

  def add_codefi_redirect_user_action
    redirect_action = UserAction.find_or_create_by(name: "Réorientation externe au codéfi")

    if codefi_redirects.any?
      # Ajouter l'action si elle n'est pas déjà présente
      user_actions << redirect_action unless user_actions.include?(redirect_action)
    else
      # Retirer l'action si elle est présente
      user_actions.delete(redirect_action) if user_actions.include?(redirect_action)
    end
  end


end