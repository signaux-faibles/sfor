# frozen_string_literal: true

# Mailer for EstablishmentTracking-related notifications.
# Add new actions here as new notification events are needed.
class EstablishmentTrackingMailer < ApplicationMailer
  # Notifies a user that they were added as a contributor (referent or participant)
  # to an EstablishmentTracking.
  #
  # @param recipient [User] the user being notified
  # @param tracking [EstablishmentTracking] the tracking they were added to
  # @param role [Symbol] :referent or :participant
  # @param added_by [User] the user who performed the action
  def contributor_added(recipient:, tracking:, role:, added_by:)
    @recipient = recipient
    @tracking = tracking
    @role = role
    @added_by = added_by
    @tracking_url = establishment_establishment_tracking_url(
      tracking.establishment,
      tracking
    )

    mail(
      to: recipient.email,
      subject: t("mailer.establishment_tracking.contributor_added.subject")
    )
  end

  # Notifies referents that a tracking has been modified.
  #
  # @param recipient [User] the referent being notified
  # @param tracking [EstablishmentTracking] the modified tracking
  # @param modified_by [User] the user who performed the update
  def tracking_updated(recipient:, tracking:, modified_by:)
    @recipient = recipient
    @tracking = tracking
    @modified_by = modified_by
    @tracking_url = establishment_establishment_tracking_url(
      tracking.establishment,
      tracking
    )

    mail(
      to: recipient.email,
      subject: t("mailer.establishment_tracking.tracking_updated.subject")
    )
  end
end
