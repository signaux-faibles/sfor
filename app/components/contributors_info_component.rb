# frozen_string_literal: true

class ContributorsInfoComponent < ViewComponent::Base
  include Pundit::Authorization

  def initialize(establishment_tracking:, establishment:, current_user:, show_manage_button: true)
    super
    @establishment_tracking = establishment_tracking
    @establishment = establishment
    @current_user = current_user
    @show_manage_button = show_manage_button
  end

  private

  attr_reader :establishment_tracking, :establishment, :current_user, :show_manage_button

  def can_manage_contributors?
    policy(establishment_tracking).manage_contributors?
  end

  def referents
    establishment_tracking.referents.includes(:entity).map(&:display_name).join(", ")
  end

  def show_manage_button?
    can_manage_contributors? && show_manage_button
  end

  def participants
    if establishment_tracking.participants.any?
      establishment_tracking.participants.includes(:entity).map(&:display_name).join(", ")
    else
      "Non renseign\u00E9"
    end
  end
end
