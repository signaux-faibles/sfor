class Establishment < ApplicationRecord
  belongs_to :department, optional: false
  belongs_to :parent_company, class_name: 'Establishment', optional: true
  has_many :sub_establishments, class_name: 'Establishment', foreign_key: 'parent_company_id'

  has_many :establishment_followers
  has_many :users, through: :establishment_followers

  # Scope to find only companies
  scope :companies, -> { where(parent_company_id: nil) }

  def company?
    parent_company_id.nil?
  end
end