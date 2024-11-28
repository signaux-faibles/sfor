class TrackingLabel < ApplicationRecord
  has_many :establishment_tracking_labels, dependent: :destroy
  has_many :establishment_trackings, through: :establishment_tracking_labels

  validates :name, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "name", "system", "updated_at"]
  end
end
