class Sector < ApplicationRecord
  has_and_belongs_to_many :establishment_trackings

  scope :ordered_by_name, -> { all.sort_by { |sector| I18n.transliterate(sector.name.downcase) } }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name]
  end
end
