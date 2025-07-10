class EstablishmentTrackingSnapshot < ApplicationRecord
  belongs_to :original_tracking, class_name: "EstablishmentTracking"
  belongs_to :tracking_event

  validates :state, presence: true

  scope :by_date_range, ->(start_date, end_date) { where(snapshot_date: start_date..end_date) }
  scope :with_state, ->(state) { where(state: state) }
  scope :with_label, ->(label_name) { where("? = ANY(label_names)", label_name) }
  scope :with_referent_email, ->(email) { where("? = ANY(referent_emails)", email) }
  scope :with_participant_email, ->(email) { where("? = ANY(participant_emails)", email) }
  scope :latest_for_tracking, lambda { |tracking_id|
    where(original_tracking_id: tracking_id).order(snapshot_date: :desc).limit(1)
  }

  # Metabase-friendly scopes
  scope :had_state_during_period, lambda { |state, start_date, end_date|
    where(state: state).where(snapshot_date: start_date..end_date)
  }

  scope :had_label_during_period, lambda { |label_name, start_date, end_date|
    where("? = ANY(label_names)", label_name).where(snapshot_date: start_date..end_date)
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      snapshot_date state establishment_siret establishment_raison_sociale
      establishment_department_code establishment_department_name
      creator_name creator_email criticality_name size_name
      start_date end_date modified_at contact
      label_names referent_names referent_emails participant_names participant_emails
      sector_names difficulty_names supporting_service_names user_action_names
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[original_tracking tracking_event establishment creator criticality size]
  end
end
