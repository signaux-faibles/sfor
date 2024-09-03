class Comment < ApplicationRecord
  belongs_to :establishment_tracking, optional: false
  belongs_to :segment, optional: true
  belongs_to :user, optional: false

  validates :content, presence: true
end
