class Criticality < ApplicationRecord
  has_many :establishment_trackings
  def self.ransackable_attributes(auth_object = nil)
    %w[id name]
  end
end
