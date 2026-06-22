# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_22_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_sectors", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "depth", null: false
    t.integer "level_one_id"
    t.string "libelle", null: false
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_activity_sectors_on_code", unique: true
    t.index ["level_one_id"], name: "index_activity_sectors_on_level_one_id"
    t.index ["parent_id"], name: "index_activity_sectors_on_parent_id"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.bigint "user_id"
    t.bigint "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "app_version"
    t.string "browser"
    t.string "city"
    t.string "country"
    t.string "device_type"
    t.string "ip"
    t.text "landing_page"
    t.float "latitude"
    t.float "longitude"
    t.string "os"
    t.string "os_version"
    t.string "platform"
    t.text "referrer"
    t.string "referring_domain"
    t.string "region"
    t.datetime "started_at"
    t.text "user_agent"
    t.bigint "user_id"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "app_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "entreprises_recentes_filter_date"
    t.boolean "maintenance_mode", default: false, null: false
    t.datetime "updated_at", null: false
  end

  create_table "campaign_companies", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_campaign_companies_on_campaign_id"
    t.index ["company_id"], name: "index_campaign_companies_on_company_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_date"
    t.string "name"
    t.datetime "start_date"
    t.datetime "updated_at", null: false
  end

  create_table "codefi_redirects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "codefi_redirects_establishment_trackings", force: :cascade do |t|
    t.bigint "codefi_redirect_id", null: false
    t.bigint "establishment_tracking_id", null: false
    t.index ["codefi_redirect_id", "establishment_tracking_id"], name: "idx_on_codefi_redirect_id_establishment_tracking_id_fd377a9600", unique: true
    t.index ["establishment_tracking_id", "codefi_redirect_id"], name: "idx_on_establishment_tracking_id_codefi_redirect_id_9ac2c8f291", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "establishment_tracking_id", null: false
    t.boolean "is_codefi", default: false, null: false
    t.bigint "network_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["establishment_tracking_id"], name: "index_comments_on_establishment_tracking_id"
    t.index ["network_id"], name: "index_comments_on_network_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "creation"
    t.string "current_procol_status"
    t.date "delai_urssaf_until"
    t.string "department", limit: 10, default: "", null: false
    t.boolean "is_active"
    t.integer "latest_effectif"
    t.string "libelle_activite_principale"
    t.string "libelle_categorie_juridique"
    t.string "libelle_naf_section"
    t.string "naf_code", limit: 6
    t.string "naf_section", limit: 1
    t.text "raison_sociale"
    t.string "siren", limit: 9
    t.string "siret_siege", limit: 14
    t.decimal "social_debt_total", precision: 15, scale: 2
    t.string "statut_juridique", limit: 10
    t.string "tracking_status"
    t.datetime "updated_at", null: false
    t.index ["department"], name: "index_companies_on_department"
    t.index ["naf_code"], name: "index_companies_on_naf_code"
    t.index ["siren"], name: "index_companies_on_siren", unique: true
  end

  create_table "company_list_ratings", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "list_name", null: false
    t.string "siren", limit: 9, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "useful", null: false
    t.string "user_email", null: false
    t.string "user_segment"
    t.index ["list_name"], name: "index_company_list_ratings_on_list_name"
    t.index ["siren", "user_email", "list_name"], name: "idx_company_list_ratings_unique", unique: true
    t.index ["siren"], name: "index_company_list_ratings_on_siren"
    t.index ["useful"], name: "index_company_list_ratings_on_useful"
    t.index ["user_email"], name: "index_company_list_ratings_on_user_email"
    t.index ["user_segment"], name: "index_company_list_ratings_on_user_segment"
  end

  create_table "company_lists", force: :cascade do |t|
    t.string "alert"
    t.datetime "created_at", null: false
    t.boolean "is_first_alert", default: false, null: false
    t.bigint "list_id", null: false
    t.decimal "score", precision: 20, scale: 10
    t.integer "score_ap"
    t.integer "score_dettes"
    t.integer "score_effectif"
    t.integer "score_financier"
    t.string "siren", limit: 9, null: false
    t.datetime "updated_at", null: false
    t.index ["list_id", "is_first_alert"], name: "index_company_lists_on_list_id_first_alert", where: "(is_first_alert = true)"
    t.index ["list_id", "score"], name: "index_company_lists_on_list_id_score_covering", include: ["siren", "alert", "score_effectif", "score_financier", "score_dettes", "score_ap"]
    t.index ["list_id"], name: "index_company_lists_on_list_id"
    t.index ["siren", "list_id"], name: "index_company_lists_on_siren_and_list_id", unique: true
    t.index ["siren"], name: "index_company_lists_on_siren"
  end

  create_table "company_score_entries", force: :cascade do |t|
    t.string "alert"
    t.string "algo"
    t.string "batch"
    t.string "code_commune", limit: 5
    t.string "code_naf"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "list_name", null: false
    t.jsonb "macro_expl"
    t.jsonb "micro_expl"
    t.string "periode"
    t.string "region"
    t.decimal "score", precision: 20, scale: 10
    t.decimal "seuil_fort", precision: 5, scale: 2
    t.decimal "seuil_modere", precision: 5, scale: 2
    t.string "siren", limit: 9, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["code_commune"], name: "index_company_score_entries_on_code_commune"
    t.index ["list_name", "siren", "alert"], name: "index_company_score_entries_on_list_name_siren_alert"
    t.index ["list_name", "siren", "created_at"], name: "index_company_score_entries_on_list_name_siren_created_at", order: { created_at: :desc }
    t.index ["list_name", "siren", "score"], name: "index_company_score_entries_on_list_name_siren_score"
    t.index ["periode"], name: "index_company_score_entries_on_periode"
    t.index ["siren", "list_name", "periode"], name: "index_company_score_entries_on_siren_and_list_name_and_periode", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.string "email"
    t.string "establishment_siret", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number_primary"
    t.string "phone_number_secondary"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["establishment_siret"], name: "index_contacts_on_establishment_siret"
  end

  create_table "criticalities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "department_geo_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "department_id", null: false
    t.bigint "geo_access_id", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_department_geo_accesses_on_department_id"
    t.index ["geo_access_id"], name: "index_department_geo_accesses_on_geo_access_id"
  end

  create_table "departments", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "region_id", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_departments_on_code", unique: true
    t.index ["name"], name: "index_departments_on_name", unique: true
    t.index ["region_id"], name: "index_departments_on_region_id"
  end

  create_table "difficulties", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_difficulties_on_name", unique: true
  end

  create_table "difficulties_establishment_trackings", force: :cascade do |t|
    t.bigint "difficulty_id", null: false
    t.bigint "establishment_tracking_id", null: false
    t.index ["difficulty_id", "establishment_tracking_id"], name: "idx_on_difficulty_id_establishment_tracking_id_777c1bd376", unique: true
    t.index ["establishment_tracking_id", "difficulty_id"], name: "idx_on_establishment_tracking_id_difficulty_id_833af32417", unique: true
  end

  create_table "entities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "establishment_tracking_actions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "establishment_tracking_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_action_id", null: false
    t.index ["establishment_tracking_id"], name: "idx_on_establishment_tracking_id_282caecb1d"
    t.index ["user_action_id"], name: "index_establishment_tracking_actions_on_user_action_id"
  end

  create_table "establishment_tracking_labels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "establishment_tracking_id", null: false
    t.bigint "tracking_label_id", null: false
    t.datetime "updated_at", null: false
    t.index ["establishment_tracking_id"], name: "idx_on_establishment_tracking_id_0ea3d45614"
    t.index ["tracking_label_id"], name: "index_establishment_tracking_labels_on_tracking_label_id"
  end

  create_table "establishment_tracking_sectors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "establishment_tracking_id", null: false
    t.bigint "sector_id", null: false
    t.datetime "updated_at", null: false
    t.index ["establishment_tracking_id"], name: "idx_on_establishment_tracking_id_dc92224b30"
    t.index ["sector_id"], name: "index_establishment_tracking_sectors_on_sector_id"
  end

  create_table "establishment_tracking_snapshots", force: :cascade do |t|
    t.text "codefi_redirect_names", default: [], array: true
    t.datetime "created_at", null: false
    t.string "creator_email"
    t.string "criticality_name"
    t.text "difficulty_names", default: [], array: true
    t.date "end_date"
    t.string "establishment_department_code"
    t.string "establishment_department_name"
    t.string "establishment_region_code"
    t.string "establishment_region_name"
    t.string "establishment_siret"
    t.text "label_names", default: [], array: true
    t.bigint "original_tracking_id", null: false
    t.text "participant_emails", default: [], array: true
    t.text "participant_entity_names", default: [], array: true
    t.text "participant_segment_names", default: [], array: true
    t.text "referent_emails", default: [], array: true
    t.text "referent_entity_names", default: [], array: true
    t.text "referent_segment_names", default: [], array: true
    t.text "sector_names", default: [], array: true
    t.string "size_name"
    t.date "start_date"
    t.string "state", null: false
    t.text "supporting_service_names", default: [], array: true
    t.bigint "tracking_event_id", null: false
    t.datetime "updated_at", null: false
    t.text "user_action_names", default: [], array: true
    t.index ["label_names"], name: "index_establishment_tracking_snapshots_on_label_names", using: :gin
    t.index ["original_tracking_id"], name: "index_establishment_tracking_snapshots_on_original_tracking_id"
    t.index ["participant_emails"], name: "index_establishment_tracking_snapshots_on_participant_emails", using: :gin
    t.index ["referent_emails"], name: "index_establishment_tracking_snapshots_on_referent_emails", using: :gin
    t.index ["state"], name: "index_establishment_tracking_snapshots_on_state"
    t.index ["tracking_event_id"], name: "index_establishment_tracking_snapshots_on_tracking_event_id"
  end

  create_table "establishment_tracking_supporting_services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "establishment_tracking_id", null: false
    t.bigint "supporting_service_id", null: false
    t.datetime "updated_at", null: false
    t.index ["establishment_tracking_id", "supporting_service_id"], name: "idx_on_establishment_tracking_id_supporting_service_60be013b8d", unique: true
    t.index ["establishment_tracking_id"], name: "idx_on_establishment_tracking_id_5d689fa02e"
    t.index ["supporting_service_id"], name: "idx_on_supporting_service_id_400181f324"
  end

  create_table "establishment_trackings", force: :cascade do |t|
    t.text "contact"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.bigint "criticality_id"
    t.datetime "discarded_at"
    t.date "end_date"
    t.string "establishment_siret", null: false
    t.date "modified_at"
    t.bigint "size_id"
    t.date "start_date"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_establishment_trackings_on_creator_id"
    t.index ["criticality_id"], name: "index_establishment_trackings_on_criticality_id"
    t.index ["discarded_at"], name: "index_establishment_trackings_on_discarded_at"
    t.index ["establishment_siret", "discarded_at"], name: "index_establishment_trackings_on_siret_and_discarded_at", where: "(discarded_at IS NULL)"
    t.index ["establishment_siret", "state"], name: "index_single_in_progress_per_establishment", unique: true, where: "((state)::text = 'in_progress'::text)"
    t.index ["establishment_siret"], name: "index_establishment_trackings_on_establishment_siret"
    t.index ["size_id"], name: "index_establishment_trackings_on_size_id"
  end

  create_table "establishments", force: :cascade do |t|
    t.text "address"
    t.string "ape", limit: 100
    t.string "code_activite", limit: 5
    t.string "code_commune", limit: 5
    t.datetime "created_at", null: false
    t.date "date_creation"
    t.string "departement", limit: 10
    t.boolean "is_active", default: false, null: false
    t.float "latitude"
    t.float "longitude"
    t.boolean "siege"
    t.string "siren", limit: 9
    t.string "siret", limit: 14
    t.datetime "updated_at", null: false
    t.index ["departement", "siege"], name: "index_establishments_on_departement_siege"
    t.index ["departement"], name: "index_establishments_on_departement"
    t.index ["siren", "siege"], name: "index_establishments_on_siren_and_siege", where: "(siege = true)"
    t.index ["siren", "siret"], name: "index_establishments_on_siren_and_siret", unique: true
    t.index ["siren"], name: "index_establishments_on_siren"
    t.index ["siren"], name: "index_establishments_on_siren_where_siege", where: "(siege = true)"
    t.index ["siret"], name: "index_establishments_on_siret", unique: true
  end

  create_table "geo_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_geo_accesses_on_name", unique: true
  end

  create_table "imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "data_freshness"
    t.date "import_date"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "inpi_bce_ratios", force: :cascade do |t|
    t.decimal "autonomie_financiere", precision: 20, scale: 6
    t.decimal "caf_sur_ca", precision: 20, scale: 6
    t.decimal "capacite_de_remboursement", precision: 20, scale: 6
    t.bigint "chiffre_d_affaires"
    t.string "confidentiality"
    t.decimal "couverture_des_interets", precision: 20, scale: 6
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.decimal "credit_clients_jours", precision: 20, scale: 6
    t.decimal "credit_fournisseurs_jours", precision: 20, scale: 6
    t.date "date_cloture_exercice", null: false
    t.bigint "ebe"
    t.bigint "ebit"
    t.bigint "marge_brute"
    t.decimal "marge_ebe", precision: 20, scale: 6
    t.decimal "poids_bfr_exploitation_sur_ca", precision: 20, scale: 6
    t.decimal "poids_bfr_exploitation_sur_ca_jours", precision: 20, scale: 6
    t.decimal "ratio_de_liquidite", precision: 20, scale: 6
    t.decimal "ratio_de_vetuste", precision: 20, scale: 6
    t.decimal "resultat_courant_avant_impots_sur_ca", precision: 20, scale: 6
    t.bigint "resultat_net"
    t.decimal "rotation_des_stocks_jours", precision: 20, scale: 6
    t.string "siren", limit: 9, null: false
    t.decimal "taux_d_endettement", precision: 20, scale: 6
    t.string "type_bilan", limit: 1, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["siren", "date_cloture_exercice", "type_bilan"], name: "idx_inpi_bce_ratios_unique_period_type", unique: true
    t.index ["siren", "date_cloture_exercice"], name: "idx_inpi_bce_ratios_latest_by_siren"
    t.index ["siren"], name: "index_inpi_bce_ratios_on_siren"
  end

  create_table "list_export_logs", force: :cascade do |t|
    t.text "active_filters"
    t.datetime "created_at", null: false
    t.datetime "exported_at", null: false
    t.string "list_name", null: false
    t.integer "results_count"
    t.datetime "updated_at", null: false
    t.string "user_email", null: false
    t.string "user_geo_zone", null: false
    t.string "user_segment", null: false
    t.index ["exported_at"], name: "index_list_export_logs_on_exported_at"
    t.index ["list_name"], name: "index_list_export_logs_on_list_name"
    t.index ["user_email", "list_name", "exported_at"], name: "index_list_export_logs_unique_daily"
    t.index ["user_email"], name: "index_list_export_logs_on_user_email"
  end

  create_table "lists", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.date "list_date"
    t.decimal "precision_alerte_elevee", precision: 5, scale: 2
    t.decimal "precision_alerte_moderee", precision: 5, scale: 2
    t.boolean "sjcf_filter_active", default: false, null: false
    t.datetime "updated_at", null: false
  end

  create_table "network_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "network_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["network_id"], name: "index_network_memberships_on_network_id"
    t.index ["user_id", "network_id"], name: "index_network_memberships_on_user_id_and_network_id", unique: true
    t.index ["user_id"], name: "index_network_memberships_on_user_id"
  end

  create_table "networks", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notification_reads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "notification_id", null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["notification_id", "user_id"], name: "index_notification_reads_on_notification_id_and_user_id", unique: true
    t.index ["notification_id"], name: "index_notification_reads_on_notification_id"
    t.index ["user_id"], name: "index_notification_reads_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "show_as_flash"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_notifications_on_created_by_id"
  end

  create_table "notifications_segments", id: false, force: :cascade do |t|
    t.bigint "notification_id", null: false
    t.bigint "segment_id", null: false
    t.index ["notification_id", "segment_id"], name: "index_notifications_segments_on_notification_id_and_segment_id", unique: true
  end

  create_table "osf_apconsos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "effectif"
    t.float "heures_consommees"
    t.string "id_demande", limit: 11
    t.float "montant"
    t.date "periode"
    t.string "siret", limit: 14
    t.datetime "updated_at", null: false
    t.index ["id_demande"], name: "index_osf_apconsos_on_id_demande"
    t.index ["siret"], name: "index_osf_apconsos_on_siret"
  end

  create_table "osf_apdemandes", primary_key: "id_demande", id: { type: :string, limit: 11 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_statut"
    t.integer "effectif"
    t.integer "effectif_autorise"
    t.integer "effectif_consomme"
    t.integer "effectif_entreprise"
    t.float "heures_consommees"
    t.float "hta"
    t.float "montant_consomme"
    t.integer "motif_recours_se"
    t.float "mta"
    t.integer "perimetre"
    t.date "periode_debut"
    t.date "periode_fin"
    t.string "siret", limit: 14
    t.datetime "updated_at", null: false
    t.index ["siret"], name: "index_osf_apdemandes_on_siret"
  end

  create_table "osf_aps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "etp_autorise"
    t.float "etp_consomme"
    t.boolean "is_last"
    t.text "motif_recours"
    t.date "periode", null: false
    t.string "siren", limit: 9, null: false
    t.string "siret", limit: 14, null: false
    t.datetime "updated_at", null: false
    t.index ["periode"], name: "index_osf_aps_on_periode"
    t.index ["siren"], name: "index_osf_aps_on_siren"
    t.index ["siret", "periode"], name: "index_osf_aps_on_siret_and_periode"
    t.index ["siret"], name: "index_osf_aps_on_siret"
  end

  create_table "osf_cotisations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "du", precision: 15, scale: 2
    t.date "periode", null: false
    t.string "siret", limit: 14, null: false
    t.datetime "updated_at", null: false
    t.index ["periode"], name: "index_osf_cotisations_on_periode"
    t.index ["siret", "periode"], name: "index_osf_cotisations_on_siret_and_periode"
    t.index ["siret"], name: "index_osf_cotisations_on_siret"
  end

  create_table "osf_debits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_last"
    t.decimal "part_ouvriere", precision: 15, scale: 2
    t.decimal "part_patronale", precision: 15, scale: 2
    t.date "periode", null: false
    t.string "siret", limit: 14, null: false
    t.datetime "updated_at", null: false
    t.index ["periode"], name: "index_osf_debits_on_periode"
    t.index ["siret", "is_last"], name: "index_osf_debits_on_siret_is_last", where: "(is_last = true)"
    t.index ["siret", "periode"], name: "index_osf_debits_on_siret_and_periode"
    t.index ["siret"], name: "index_osf_debits_on_siret"
  end

  create_table "osf_delais", force: :cascade do |t|
    t.string "action", limit: 50
    t.datetime "created_at", null: false
    t.date "date_creation"
    t.date "date_echeance"
    t.integer "duree_delai"
    t.decimal "montant_echeancier", precision: 15, scale: 2
    t.string "siret", limit: 14, null: false
    t.string "stade", limit: 50
    t.datetime "updated_at", null: false
    t.index ["date_creation"], name: "index_osf_delais_on_date_creation"
    t.index ["date_echeance"], name: "index_osf_delais_on_date_echeance"
    t.index ["siret", "date_echeance"], name: "index_osf_delais_on_siret_date_echeance"
    t.index ["siret"], name: "index_osf_delais_on_siret"
  end

  create_table "osf_effectifs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "effectif"
    t.boolean "is_latest"
    t.date "periode", null: false
    t.string "siret", limit: 14, null: false
    t.datetime "updated_at", null: false
    t.index ["periode"], name: "index_osf_effectifs_on_periode"
    t.index ["siret", "periode"], name: "index_osf_effectifs_on_siret_and_periode"
    t.index ["siret"], name: "idx_osf_effectifs_siret_latest", where: "(is_latest = true)"
    t.index ["siret"], name: "index_osf_effectifs_on_siret"
  end

  create_table "osf_ent_effectifs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "effectif"
    t.boolean "is_latest"
    t.date "periode", null: false
    t.string "siren", limit: 9, null: false
    t.datetime "updated_at", null: false
    t.index ["periode"], name: "index_osf_ent_effectifs_on_periode"
    t.index ["siren", "is_latest", "effectif"], name: "index_osf_ent_effectifs_on_siren_is_latest_effectif", where: "(is_latest = true)"
    t.index ["siren", "periode"], name: "index_osf_ent_effectifs_on_siren_and_periode"
    t.index ["siren"], name: "index_osf_ent_effectifs_on_siren"
  end

  create_table "osf_procols", force: :cascade do |t|
    t.text "action_procol"
    t.datetime "created_at", null: false
    t.date "date_effet"
    t.string "libelle_procol"
    t.string "siren", limit: 9
    t.text "stade_procol"
    t.datetime "updated_at", null: false
    t.index ["date_effet"], name: "index_osf_procols_on_date_effet"
    t.index ["siren", "action_procol", "date_effet"], name: "index_osf_procols_on_siren_action_procol_date_effet", order: { date_effet: :desc }
    t.index ["siren", "date_effet"], name: "index_osf_procols_on_siren_and_date_effet"
    t.index ["siren"], name: "index_osf_procols_on_siren"
  end

  create_table "out_of_zone_accesses", force: :cascade do |t|
    t.datetime "accessed_at", null: false
    t.text "accessed_url", null: false
    t.datetime "created_at", null: false
    t.string "resource_department", null: false
    t.string "resource_identifier", null: false
    t.string "resource_type", null: false
    t.datetime "updated_at", null: false
    t.string "user_email", null: false
    t.string "user_geo_zone", null: false
    t.string "user_segment", null: false
    t.index ["accessed_at"], name: "index_out_of_zone_accesses_on_accessed_at"
    t.index ["resource_department"], name: "index_out_of_zone_accesses_on_resource_department"
    t.index ["user_email"], name: "index_out_of_zone_accesses_on_user_email"
    t.index ["user_segment"], name: "index_out_of_zone_accesses_on_user_segment"
  end

  create_table "rating_reasons", force: :cascade do |t|
    t.string "code", limit: 10, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "date_add", limit: 50
    t.text "libelle", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["code"], name: "index_rating_reasons_on_code", unique: true
  end

  create_table "rating_reasons_ratings", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "rating_id", null: false
    t.bigint "reason_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["rating_id", "reason_id"], name: "idx_rating_reasons_ratings_unique", unique: true
    t.index ["rating_id"], name: "index_rating_reasons_ratings_on_rating_id"
    t.index ["reason_id"], name: "index_rating_reasons_ratings_on_reason_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "libelle", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "sectors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "segments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "network_id", null: false
    t.datetime "updated_at", null: false
    t.index ["network_id"], name: "index_segments_on_network_id"
  end

  create_table "sizes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "sjcf_companies", force: :cascade do |t|
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "libelle_liste", null: false
    t.string "siren", limit: 9, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["libelle_liste"], name: "index_sjcf_companies_on_libelle_liste"
    t.index ["siren", "libelle_liste"], name: "index_sjcf_companies_on_siren_and_libelle_liste", unique: true
    t.index ["siren"], name: "index_sjcf_companies_on_siren"
  end

  create_table "summaries", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "establishment_tracking_id", null: false
    t.boolean "is_codefi", default: false, null: false
    t.datetime "locked_at"
    t.integer "locked_by"
    t.bigint "network_id", null: false
    t.datetime "updated_at", null: false
    t.index ["establishment_tracking_id", "is_codefi"], name: "index_summaries_on_establishment_tracking_id_and_is_codefi", unique: true, where: "(is_codefi = true)"
    t.index ["establishment_tracking_id", "network_id"], name: "index_unique_network_summary", unique: true
    t.index ["establishment_tracking_id"], name: "index_summaries_on_establishment_tracking_id"
    t.index ["network_id"], name: "index_summaries_on_network_id"
  end

  create_table "supporting_services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tracking_events", force: :cascade do |t|
    t.json "changes_summary"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "establishment_tracking_id", null: false
    t.string "event_type", null: false
    t.bigint "triggered_by_user_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tracking_events_on_created_at"
    t.index ["establishment_tracking_id", "created_at"], name: "idx_on_establishment_tracking_id_created_at_45a748e8c5"
    t.index ["establishment_tracking_id"], name: "index_tracking_events_on_establishment_tracking_id"
    t.index ["event_type"], name: "index_tracking_events_on_event_type"
    t.index ["triggered_by_user_id"], name: "index_tracking_events_on_triggered_by_user_id"
  end

  create_table "tracking_labels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.boolean "system", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_tracking_labels_on_discarded_at"
  end

  create_table "tracking_participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "establishment_tracking_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["establishment_tracking_id"], name: "index_tracking_participants_on_establishment_tracking_id"
    t.index ["user_id"], name: "index_tracking_participants_on_user_id"
  end

  create_table "tracking_referents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "establishment_tracking_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["establishment_tracking_id"], name: "index_tracking_referents_on_establishment_tracking_id"
    t.index ["user_id"], name: "index_tracking_referents_on_user_id"
  end

  create_table "user_actions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_user_actions_on_discarded_at"
  end

  create_table "user_departments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "department_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["department_id"], name: "index_user_departments_on_department_id"
    t.index ["user_id"], name: "index_user_departments_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "ambassador", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.text "description"
    t.datetime "discarded_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.bigint "entity_id", null: false
    t.text "feedbacks"
    t.string "first_name"
    t.bigint "geo_access_id", null: false
    t.string "id_token"
    t.datetime "last_confidentiality_acknowledged_at"
    t.date "last_contact"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "level", default: "A", null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.bigint "segment_id", null: false
    t.integer "sign_in_count"
    t.string "time_zone"
    t.boolean "trained", default: false, null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["entity_id"], name: "index_users_on_entity_id"
    t.index ["geo_access_id"], name: "index_users_on_geo_access_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["segment_id"], name: "index_users_on_segment_id"
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "zones", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_zones_on_key", unique: true
  end

  add_foreign_key "activity_sectors", "activity_sectors", column: "level_one_id"
  add_foreign_key "activity_sectors", "activity_sectors", column: "parent_id"
  add_foreign_key "campaign_companies", "campaigns"
  add_foreign_key "campaign_companies", "companies"
  add_foreign_key "comments", "establishment_trackings"
  add_foreign_key "comments", "networks"
  add_foreign_key "comments", "users"
  add_foreign_key "company_lists", "lists", on_delete: :cascade
  add_foreign_key "department_geo_accesses", "departments"
  add_foreign_key "department_geo_accesses", "geo_accesses"
  add_foreign_key "departments", "regions"
  add_foreign_key "establishment_tracking_actions", "establishment_trackings"
  add_foreign_key "establishment_tracking_actions", "user_actions"
  add_foreign_key "establishment_tracking_labels", "establishment_trackings"
  add_foreign_key "establishment_tracking_labels", "tracking_labels"
  add_foreign_key "establishment_tracking_sectors", "establishment_trackings"
  add_foreign_key "establishment_tracking_sectors", "sectors"
  add_foreign_key "establishment_tracking_snapshots", "establishment_trackings", column: "original_tracking_id"
  add_foreign_key "establishment_tracking_snapshots", "tracking_events"
  add_foreign_key "establishment_tracking_supporting_services", "establishment_trackings"
  add_foreign_key "establishment_tracking_supporting_services", "supporting_services"
  add_foreign_key "establishment_trackings", "criticalities"
  add_foreign_key "establishment_trackings", "sizes"
  add_foreign_key "establishment_trackings", "users", column: "creator_id"
  add_foreign_key "network_memberships", "networks"
  add_foreign_key "network_memberships", "users"
  add_foreign_key "notification_reads", "notifications"
  add_foreign_key "notification_reads", "users"
  add_foreign_key "notifications", "users", column: "created_by_id"
  add_foreign_key "rating_reasons_ratings", "company_list_ratings", column: "rating_id", on_delete: :cascade
  add_foreign_key "rating_reasons_ratings", "rating_reasons", column: "reason_id", on_delete: :cascade
  add_foreign_key "segments", "networks"
  add_foreign_key "summaries", "establishment_trackings"
  add_foreign_key "summaries", "networks"
  add_foreign_key "tracking_events", "establishment_trackings"
  add_foreign_key "tracking_events", "users", column: "triggered_by_user_id"
  add_foreign_key "tracking_participants", "establishment_trackings"
  add_foreign_key "tracking_participants", "users"
  add_foreign_key "tracking_referents", "establishment_trackings"
  add_foreign_key "tracking_referents", "users"
  add_foreign_key "user_departments", "departments"
  add_foreign_key "user_departments", "users"
  add_foreign_key "users", "entities"
  add_foreign_key "users", "geo_accesses"
  add_foreign_key "users", "segments"
end
