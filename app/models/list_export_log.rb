class ListExportLog < ApplicationRecord
  validates :exported_at, :user_email, :user_geo_zone, :user_segment, :list_name, presence: true

  # Check if an export with the same user, list, and filters already exists today
  def self.already_exported_today?(user_email:, list_name:, filters_hash:)
    today_start = Time.current.beginning_of_day
    today_end = Time.current.end_of_day

    where(user_email: user_email, list_name: list_name)
      .where(exported_at: today_start..today_end)
      .exists?(active_filters: filters_hash)
  end
end
