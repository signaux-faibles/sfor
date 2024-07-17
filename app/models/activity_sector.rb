class ActivitySector < ApplicationRecord
  belongs_to :parent, class_name: 'ActivitySector', optional: true
  belongs_to :level_one, class_name: 'ActivitySector', optional: true

  has_many :subsectors, class_name: 'ActivitySector', foreign_key: 'parent_id'
  has_many :establishments
  has_many :level_one_establishments, class_name: 'Establishment', foreign_key: 'level_one_activity_sector_id'

  validates :depth, presence: true
  validates :code, presence: true, uniqueness: true
  validates :libelle, presence: true
end
