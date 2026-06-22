class List < ApplicationRecord
  scope :latest_first, -> { order(code: :desc) }

  PRECISION_ALERTE_RANGE = (0..100)

  validates :precision_alerte_elevee,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :precision_alerte_moderee,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true

  has_many :company_lists, dependent: :destroy
  # company_lists has siren column, which matches companies.siren
  has_many :companies, -> { distinct }, through: :company_lists, source: :company
  has_many :company_score_entries, foreign_key: :list_name, primary_key: :label, dependent: :destroy
  has_many :company_list_ratings, foreign_key: :list_name, primary_key: :label, dependent: :destroy

  # validates :label, presence: true, uniqueness: true
  # validates :code, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[code created_at id id_value label precision_alerte_elevee precision_alerte_moderee updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[company_lists companies company_score_entries company_list_ratings]
  end

  def self.latest
    latest_first.first
  end

  def latest?
    id == self.class.latest&.id
  end
end
