class SupportingService < ApplicationRecord
  has_and_belongs_to_many :establishment_trackings, 
                         join_table: :establishment_tracking_supporting_services

  validates :name, presence: true
end 