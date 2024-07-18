require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    created_trackings: Field::HasMany,
    current_sign_in_at: Field::DateTime,
    current_sign_in_ip: Field::String,
    email: Field::String,
    encrypted_password: Field::String,
    first_name: Field::String,
    id_token: Field::String,
    last_name: Field::String,
    last_sign_in_at: Field::DateTime,
    last_sign_in_ip: Field::String,
    participated_trackings: Field::HasMany,
    provider: Field::String,
    remember_created_at: Field::DateTime,
    reset_password_sent_at: Field::DateTime,
    reset_password_token: Field::String,
    roles: Field::HasMany,
    sign_in_count: Field::Number,
    tracking_participants: Field::HasMany,
    uid: Field::String,
    wekan_document_id: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    created_trackings
    current_sign_in_at
    current_sign_in_ip
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    created_trackings
    current_sign_in_at
    current_sign_in_ip
    email
    encrypted_password
    first_name
    id_token
    last_name
    last_sign_in_at
    last_sign_in_ip
    participated_trackings
    provider
    remember_created_at
    reset_password_sent_at
    reset_password_token
    roles
    sign_in_count
    tracking_participants
    uid
    wekan_document_id
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    created_trackings
    current_sign_in_at
    current_sign_in_ip
    email
    encrypted_password
    first_name
    id_token
    last_name
    last_sign_in_at
    last_sign_in_ip
    participated_trackings
    provider
    remember_created_at
    reset_password_sent_at
    reset_password_token
    roles
    sign_in_count
    tracking_participants
    uid
    wekan_document_id
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

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(user)
  #   "User ##{user.id}"
  # end
end
