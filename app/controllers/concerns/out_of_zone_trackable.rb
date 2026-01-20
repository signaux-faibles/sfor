module OutOfZoneTrackable
  extend ActiveSupport::Concern

  private

  def track_out_of_zone_access(resource) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return unless current_user
    return if user_has_access_to_resource?(resource)

    OutOfZoneAccess.create!(
      accessed_at: Time.current,
      user_email: current_user.email,
      user_geo_zone: current_user.geo_access.name,
      resource_department: extract_department_code(resource),
      user_segment: current_user.segment.name,
      accessed_url: request.original_url,
      resource_type: resource.class.name,
      resource_identifier: resource.is_a?(Company) ? resource.siren : resource.siret
    )
  rescue StandardError => e
    Sentry.capture_exception(e, extra: {
                               user_email: current_user&.email,
                               resource_type: resource.class.name,
                               resource_identifier: resource.try(:siren) || resource.try(:siret)
                             })
  end

  def user_has_access_to_resource?(resource)
    department_code = extract_department_code(resource)
    current_user.departments.exists?(code: department_code)
  end

  def extract_department_code(resource)
    case resource
    when Company
      resource.read_attribute(:department)
    when Establishment
      resource.departement
    end
  end
end
