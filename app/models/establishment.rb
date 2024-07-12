class Establishment < ApplicationRecord
  belongs_to :department, optional: false
  belongs_to :parent_company, class_name: 'Establishment', optional: true
  has_many :sub_establishments, class_name: 'Establishment', foreign_key: 'parent_company_id'

  has_many :establishment_trackings

  has_many :campaign_memberships
  has_many :campaigns, through: :campaign_memberships

  validates :siret, presence: true, uniqueness: true

  # Scope to find only companies
  scope :companies, -> { where(parent_company_id: nil) }
  scope :by_campaign, -> (campaign_id) { joins(:campaign_memberships).where(campaign_memberships: { campaign_id: campaign_id }) if campaign_id.present? }
  def company?
    parent_company_id.nil?
  end
end