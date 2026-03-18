class NotificationRead < ApplicationRecord
  belongs_to :notification
  belongs_to :user

  validates :notification_id, uniqueness: { scope: :user_id }
end
