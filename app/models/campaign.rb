class Campaign < ApplicationRecord
  has_many :campaign_companies
  has_many :companies, through: :campaign_companies

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "end_date", "id", "id_value", "name", "start_date", "updated_at"]
  end
end