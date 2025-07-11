require "administrate/base_dashboard"

class EstablishmentTrackingDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    siret: Field::String,
    name: Field::String,
    address: Field::String,
    city: Field::String,
    postal_code: Field::String,
    department: Field::String,
    region: Field::String,
    activity_code: Field::String,
    legal_form: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    contact: Field::HasOne,
    size: Field::BelongsTo,
    criticality: Field::BelongsTo,
    difficulties: Field::HasMany,
    supporting_services: Field::HasMany,
    summaries: Field::HasMany,
    comments: Field::HasMany
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    siret
    name
    city
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    siret
    name
    address
    city
    postal_code
    department
    region
    activity_code
    legal_form
    created_at
    updated_at
    contact
    size
    criticality
    difficulties
    supporting_services
    summaries
    comments
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    siret
    name
    address
    city
    postal_code
    department
    region
    activity_code
    legal_form
    contact
    size
    criticality
    difficulties
    supporting_services
    summaries
    comments
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how establishment trackings are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(establishment_tracking)
    establishment_tracking.id
  end
end
