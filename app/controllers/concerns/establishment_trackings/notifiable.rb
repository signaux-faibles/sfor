# frozen_string_literal: true

# Controller concern that dispatches email notifications for EstablishmentTracking events.
#
# To add a new notification type:
#   1. Add a new action to EstablishmentTrackingMailer
#   2. Add a corresponding private method here that calls it
#   3. Call that method from the relevant controller action
module EstablishmentTrackings::Notifiable
  extend ActiveSupport::Concern

  private

  # Sends a notification email to each newly added referent and participant,
  # skipping the user who performed the action.
  def notify_added_contributors(added_by:, tracking:, added_referents: [], added_participants: [])
    notify_contributors(added_referents, role: :referent, added_by: added_by, tracking: tracking)
    notify_contributors(added_participants, role: :participant, added_by: added_by, tracking: tracking)
  end

  def notify_contributors(users, role:, added_by:, tracking:)
    users.each do |user|
      next if user == added_by

      EstablishmentTrackingMailer.contributor_added(
        recipient: user,
        tracking: tracking,
        role: role,
        added_by: added_by
      ).deliver_later
    end
  end
end
