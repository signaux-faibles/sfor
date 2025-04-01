class Criticality < ApplicationRecord
  has_many :establishment_trackings, dependent: :nullify

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name]
  end
end
