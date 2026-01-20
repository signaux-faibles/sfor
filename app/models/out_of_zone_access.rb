class OutOfZoneAccess < ApplicationRecord
  validates :accessed_at, :user_email, :user_geo_zone, :resource_department,
            :user_segment, :accessed_url, :resource_type, :resource_identifier,
            presence: true

  validates :resource_type, inclusion: { in: %w[Company Establishment] }
end
