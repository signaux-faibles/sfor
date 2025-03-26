class Sector < ApplicationRecord
  has_and_belongs_to_many :establishment_trackings

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name]
  end
end
