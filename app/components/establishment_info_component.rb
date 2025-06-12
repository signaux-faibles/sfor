# frozen_string_literal: true

class EstablishmentInfoComponent < ViewComponent::Base
  include Pundit::Authorization

  def initialize(establishment_tracking:, establishment:, current_user:, show_edit_button: true,
                 confirmation_mode: false)
    super
    @establishment_tracking = establishment_tracking
    @establishment = establishment
    @current_user = current_user
    @show_edit_button = show_edit_button
    @confirmation_mode = confirmation_mode
  end

  private

  attr_reader :establishment_tracking, :establishment, :current_user, :show_edit_button, :confirmation_mode

  def can_edit?
    policy(establishment_tracking).edit?
  end

  def show_edit_button?
    show_edit_button && can_edit?
  end

  def confirmation_mode?
    confirmation_mode
  end
end
