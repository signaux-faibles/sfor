class Company < ApplicationRecord
  belongs_to :activity_sector, optional: true
  belongs_to :department, foreign_key: :department, primary_key: :code, optional: false
  has_many :establishments, foreign_key: :siren, primary_key: :siren, dependent: :nullify

  has_many :campaign_companies, dependent: :destroy
  has_many :campaigns, through: :campaign_companies

  has_many :company_lists, foreign_key: :siren, primary_key: :siren, dependent: :destroy
  has_many :lists, through: :company_lists
  has_many :company_score_entries, foreign_key: :siren, primary_key: :siren, dependent: :destroy
  has_many :osf_procols, foreign_key: :siren, primary_key: :siren, dependent: :destroy
  has_many :company_list_ratings, foreign_key: :siren, primary_key: :siren, dependent: :destroy

  validates :siren, presence: true, uniqueness: true
  validates :department, presence: true, length: { maximum: 10 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value siren raison_sociale statut_juridique creation updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[campaign_companies campaigns company_lists establishments lists]
  end

  def establishments_ordered
    establishments.order(siege: :desc)
  end

  def to_param
    siren
  end
end
