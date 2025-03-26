class Company < ApplicationRecord
  belongs_to :department
  belongs_to :activity_sector, optional: true
  has_many :establishments

  has_many :campaign_companies
  has_many :campaigns, through: :campaign_companies

  has_many :company_lists
  has_many :lists, through: :company_lists

  validates :siren, presence: true, uniqueness: true
  validates :siret, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id id_value siren siret raison_sociale effectif updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[campaign_companies campaigns company_lists establishments lists department activity_sector]
  end

  def establishments_ordered
    establishments.order(is_siege: :desc)
  end
end
