# frozen_string_literal: true

class TrackingInfoComponent < ViewComponent::Base
  include Pundit::Authorization

  def initialize(establishment_tracking:, establishment:, current_user:, options: {})
    super
    @establishment_tracking = establishment_tracking
    @establishment = establishment
    @current_user = current_user
    @show_edit_button = options.fetch(:show_edit_button, true)
    @show_create_button = options.fetch(:show_create_button, true)
    @confirmation_mode = options.fetch(:confirmation_mode, false)
  end

  private

  attr_reader :establishment_tracking, :establishment, :current_user, :show_edit_button, :show_create_button,
              :confirmation_mode

  def can_edit?
    policy(establishment_tracking).edit?
  end

  def show_create_button?
    show_create_button && policy(establishment_tracking).create?
  end

  def show_edit_button?
    show_edit_button && can_edit?
  end

  def confirmation_mode?
    confirmation_mode
  end

  def format_date(date)
    date.present? ? l(date, format: :default) : "-"
  end

  def format_tags(items)
    if items.any?
      items.map { |item| tag.span(item.name, class: "fr-tag fr-tag--sm") }.join.html_safe
    else
      tag.span("Non renseign\u00E9")
    end
  end
end
