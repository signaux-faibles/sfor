class Company < ApplicationRecord
  belongs_to :activity_sector, optional: true
  has_many :establishments, foreign_key: :siren, primary_key: :siren, dependent: :nullify

  has_many :campaign_companies, dependent: :destroy
  has_many :campaigns, through: :campaign_companies

  has_many :company_lists, dependent: :destroy
  has_many :lists, through: :company_lists

  validates :siren, presence: true, uniqueness: true

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
