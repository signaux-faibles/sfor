# frozen_string_literal: true

# Handles tracking state management functionality
module EstablishmentTrackings::StateManageable
  extend ActiveSupport::Concern

  private

  def prepare_label_params(tracking_params)
    submitted_labels = tracking_params[:tracking_label_ids]&.compact_blank&.map(&:to_i) || []
    existing_labels = @establishment_tracking.tracking_labels.where(system: false).pluck(:id)
    combined_ids = (submitted_labels + existing_labels).uniq
    tracking_params.except(:tracking_label_ids).merge(tracking_label_ids: combined_ids)
  end
end
