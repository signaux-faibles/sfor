require "administrate/base_dashboard"

class EstablishmentDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    activite_partielle: Field::Boolean,
    activity_sector: Field::BelongsTo,
    alert: Field::Text,
    apconso_heure_consomme: Field::Number,
    apconso_montant: Field::Number,
    arrete_bilan: Field::Date,
    chiffre_affaire: Field::Number.with_options(decimals: 2),
    child_establishments: Field::HasMany,
    code_activite: Field::Text,
    code_territoire_industrie: Field::Text,
    commune: Field::Text,
    company: Field::BelongsTo,
    date_creation_entreprise: Field::DateTime,
    date_effectif: Field::Date,
    date_entreprise: Field::Date,
    date_last_procol: Field::Date,
    date_ouverture_etablissement: Field::DateTime,
    department: Field::BelongsTo,
    detail_score: Field::String.with_options(searchable: false),
    dette_urssaf: Field::Number.with_options(decimals: 2),
    effectif: Field::Number.with_options(decimals: 2),
    effectif_entreprise: Field::Number.with_options(decimals: 2),
    establishment_trackings: Field::HasMany,
    etat_administratif: Field::Text,
    etat_administratif_entreprise: Field::Text,
    excedent_brut_d_exploitation: Field::Number.with_options(decimals: 2),
    exercice_diane: Field::Number,
    first_alert: Field::Boolean,
    first_list_entreprise: Field::Text,
    first_list_etablissement: Field::Text,
    first_red_list_entreprise: Field::Text,
    first_red_list_etablissement: Field::Text,
    has_delai: Field::Boolean,
    hausse_urssaf: Field::Boolean,
    is_siege: Field::Boolean,
    last_alert: Field::Text,
    last_list: Field::Text,
    last_procol: Field::Text,
    level_one_activity_sector: Field::BelongsTo,
    libelle_n1: Field::Text,
    libelle_n5: Field::Text,
    libelle_territoire_industrie: Field::Text,
    liste: Field::Text,
    parent_establishment: Field::BelongsTo,
    periode_urssaf: Field::Date,
    presence_part_salariale: Field::Boolean,
    prev_chiffre_affaire: Field::Number.with_options(decimals: 2),
    prev_excedent_brut_d_exploitation: Field::Number.with_options(decimals: 2),
    prev_resultat_expl: Field::Number.with_options(decimals: 2),
    raison_sociale: Field::Text,
    raison_sociale_groupe: Field::Text,
    resultat_expl: Field::Number.with_options(decimals: 2),
    roles: Field::Text,
    secteur_covid: Field::Text,
    siren: Field::String,
    siret: Field::String,
    statut_juridique_n1: Field::Text,
    statut_juridique_n2: Field::Text,
    statut_juridique_n3: Field::Text,
    territoire_industrie: Field::Boolean,
    valeur_score: Field::Number.with_options(decimals: 2),
    variation_ca: Field::Number.with_options(decimals: 2),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    is_siege
    raison_sociale
    siren
    siret
    activity_sector
    parent_establishment
    establishment_trackings
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    siren
    siret
    raison_sociale
    activity_sector
    child_establishments
    code_activite
    code_territoire_industrie
    commune
    company
    department
    establishment_trackings
    is_siege
    level_one_activity_sector
    parent_establishment
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    siren
    siret
    raison_sociale
    activity_sector
    child_establishments
    code_activite
    code_territoire_industrie
    commune
    company
    department
    establishment_trackings
    is_siege
    level_one_activity_sector
    parent_establishment
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

  # Overwrite this method to customize how establishments are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(establishment)
    "#{establishment.siret}"
  end
end
