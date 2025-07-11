class EstablishmentTracking < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include AASM
  has_paper_trail

  # EstablishmentTracking can be soft deleted
  include Discard::Model

  belongs_to :creator, class_name: "User"
  belongs_to :establishment

  has_many :tracking_referents, dependent: :destroy
  has_many :referents, through: :tracking_referents, source: :user
  has_many :discarded_referents, -> { discarded }, through: :tracking_referents, source: :user

  has_many :tracking_participants, dependent: :destroy
  has_many :participants, through: :tracking_participants, source: :user
  has_many :discarded_participants, -> { discarded }, through: :tracking_participants, source: :user

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
  has_and_belongs_to_many :supporting_services, join_table: :establishment_tracking_supporting_services

  before_save :update_modified_at_if_criticality_changed
  before_create :set_modified_at

  attr_accessor :skip_update_modified_at

  validates :referents, presence: true
  validate :at_least_one_active_referent, on: :update
  validate :single_active_tracking, if: -> { state.in?(%w[in_progress under_surveillance]) }

  scope :in_progress, -> { where(state: "in_progress") }
  scope :completed, -> { where(state: "completed") }
  scope :under_surveillance, -> { where(state: "under_surveillance") }

  scope :with_user_as_referent_or_participant, lambda { |user|
    left_joins(:tracking_participants, :tracking_referents)
      .where("tracking_participants.user_id = :user_id OR tracking_referents.user_id = :user_id", user_id: user.id)
      .distinct
  }

  scope :by_network_participants, lambda { |network_ids|
    left_joins(tracking_participants: { user: { network_memberships: :network } })
      .where.not(networks: { name: "CODEFI" })
      .where(networks: { id: network_ids })
  }

  scope :by_network_referents, lambda { |network_ids|
    left_joins(tracking_referents: { user: { network_memberships: :network } })
      .where.not(networks: { name: "CODEFI" })
      .where(networks: { id: network_ids })
  }

  scope :by_network, lambda { |network_ids|
    where(id: by_network_participants(network_ids))
      .or(where(id: by_network_referents(network_ids)))
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at creator_id end_date establishment_id id id_value start_date state
       criticality_id size_id updated_at modified_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[comments creator establishment establishment_tracking_labels participants referents summaries tracking_labels
       tracking_participants tracking_referents sectors supporting_services]
  end

  aasm column: "state" do
    state :in_progress, initial: true
    state :completed
    state :under_surveillance

    event :complete do
      before do
        self.end_date = Time.zone.today
      end
      transitions from: %i[in_progress under_surveillance completed], to: :completed
    end

    event :start_surveillance do
      transitions from: %i[in_progress completed under_surveillance], to: :under_surveillance
    end

    event :resume do
      transitions from: %i[completed under_surveillance in_progress], to: :in_progress
    end
  end

  # Add a method to get summary-related versions
  def summary_versions
    versions.where(event: %w[summary_created summary_updated])
  end

  # Add a method to get the last summary change
  def last_summary_change
    summary_versions.last
  end

  # Add a method to get comment-related versions
  def comment_versions
    versions.where(event: %w[comment_created comment_modified comment_deleted])
  end

  # Add a method to get the last comment change
  def last_comment_change
    comment_versions.last
  end

  private

  def at_least_one_active_referent
    return if referents.kept.any?

    errors.add(:referents, :at_least_one_active_required)
  end

  def single_active_tracking
    if establishment.establishment_trackings
                    .where(state: %w[in_progress under_surveillance])
                    .where.not(id: id) # Exclude the current record if updating
                    .exists?
      errors.add(:state, 'Un accompagnement "en cours" ou "sous surveillance" existe déjà pour cet établissement.')
    end
  end

  def set_modified_at
    return if @skip_modified_at_update

    self.modified_at = Date.current
  end

  def update_modified_at_if_criticality_changed
    return if @skip_modified_at_update

    self.modified_at = Date.current if criticality_id_changed?
  end
end
