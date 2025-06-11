# frozen_string_literal: true

class TrackingInfoComponent < ViewComponent::Base
  include Pundit::Authorization

  def initialize(establishment_tracking:, establishment:, current_user:, show_edit_button: true)
    super
    @establishment_tracking = establishment_tracking
    @establishment = establishment
    @current_user = current_user
    @show_edit_button = show_edit_button
  end

  private

  attr_reader :establishment_tracking, :establishment, :current_user, :show_edit_button

  def can_edit?
    policy(establishment_tracking).edit?
  end

  def show_edit_button?
    show_edit_button && can_edit?
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
