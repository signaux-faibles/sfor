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
  end
end