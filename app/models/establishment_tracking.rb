class EstablishmentTracking < ApplicationRecord
  include AASM

  belongs_to :creator, class_name: 'User'
  belongs_to :establishment

  has_many :tracking_referents, dependent: :destroy
  has_many :referents, through: :tracking_referents, source: :user

  has_many :tracking_participants, dependent: :destroy
  has_many :participants, through: :tracking_participants, source: :user

  has_many :establishment_tracking_labels, dependent: :destroy
  has_many :tracking_labels, through: :establishment_tracking_labels

  has_many :summaries, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :referents, presence: true

  scope :in_progress, -> { where(state: 'in_progress') }
  scope :completed, -> { where(state: 'completed') }
  scope :cancelled, -> { where(state: 'cancelled') }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "creator_id", "end_date", "establishment_id", "id", "id_value", "start_date", "state", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["comments", "creator", "establishment", "establishment_tracking_labels", "participants", "referents", "summaries", "tracking_labels", "tracking_participants", "tracking_referents"]
  end

  aasm column: 'state' do
    state :in_progress, initial: true
    state :completed
    state :cancelled

    event :complete do
      before do
        self.end_date = Date.today
      end
      transitions from: :in_progress, to: :completed
    end

    event :cancel do
      transitions from: :in_progress, to: :cancelled
    end

    #TODO : permettre le passage d'un statut à l'autre sans restrictions (restore ? monitor ?)
  end
end