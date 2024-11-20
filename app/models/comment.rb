class Comment < ApplicationRecord
  belongs_to :establishment_tracking, optional: false
  belongs_to :network, optional: false
  belongs_to :user, optional: false

  validates :content, presence: true
  validates :network_id, presence: true
end
