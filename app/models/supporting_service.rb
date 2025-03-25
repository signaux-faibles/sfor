class SupportingService < ApplicationRecord
  has_and_belongs_to_many :establishment_trackings, 
                         join_table: :establishment_tracking_supporting_services

  validates :name, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "name", "updated_at"]
  end
end 