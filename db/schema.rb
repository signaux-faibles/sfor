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

ActiveRecord::Schema[7.1].define(version: 2025_02_19_135402) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "activity_sectors", force: :cascade do |t|
    t.integer "depth", null: false
    t.string "code", null: false
    t.string "libelle", null: false
    t.integer "parent_id"
    t.integer "level_one_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_activity_sectors_on_code", unique: true
    t.index ["level_one_id"], name: "index_activity_sectors_on_level_one_id"
    t.index ["parent_id"], name: "index_activity_sectors_on_parent_id"
  end

  create_table "campaign_companies", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "company_id", null: false
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_campaign_companies_on_campaign_id"
    t.index ["company_id"], name: "index_campaign_companies_on_company_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.bigint "establishment_tracking_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_codefi", default: false, null: false
    t.bigint "user_id", null: false
    t.bigint "network_id", null: false
    t.index ["establishment_tracking_id"], name: "index_comments_on_establishment_tracking_id"
    t.index ["network_id"], name: "index_comments_on_network_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "siren", null: false
    t.string "siret", null: false
    t.string "raison_sociale"
    t.integer "effectif"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "department_id", null: false
    t.bigint "activity_sector_id"
    t.index ["activity_sector_id"], name: "index_companies_on_activity_sector_id"
    t.index ["department_id"], name: "index_companies_on_department_id"
    t.index ["siren"], name: "index_companies_on_siren", unique: true
    t.index ["siret"], name: "index_companies_on_siret", unique: true
  end

  create_table "company_lists", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_lists_on_company_id"
    t.index ["list_id"], name: "index_company_lists_on_list_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "establishment_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.string "phone_number_primary"
    t.string "phone_number_secondary"
    t.string "email"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.index ["establishment_id"], name: "index_contacts_on_establishment_id"
  end

  create_table "criticalities", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "department_geo_accesses", force: :cascade do |t|
    t.bigint "geo_access_id", null: false
    t.bigint "department_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_department_geo_accesses_on_department_id"
    t.index ["geo_access_id"], name: "index_department_geo_accesses_on_geo_access_id"
  end

  create_table "departments", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "region_id", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
    t.index ["region_id"], name: "index_departments_on_region_id"
  end

  create_table "entities", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "establishment_tracking_actions", force: :cascade do |t|
    t.bigint "establishment_tracking_id", null: false
    t.bigint "action_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_id"], name: "index_establishment_tracking_actions_on_action_id"
    t.index ["establishment_tracking_id"], name: "idx_on_establishment_tracking_id_282caecb1d"
  end

  create_table "establishment_tracking_labels", force: :cascade do |t|
    t.bigint "establishment_tracking_id", null: false
    t.bigint "tracking_label_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["establishment_tracking_id"], name: "idx_on_establishment_tracking_id_0ea3d45614"
    t.index ["tracking_label_id"], name: "index_establishment_tracking_labels_on_tracking_label_id"
  end

  create_table "establishment_tracking_sectors", force: :cascade do |t|
    t.bigint "establishment_tracking_id", null: false
    t.bigint "sector_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["establishment_tracking_id"], name: "idx_on_establishment_tracking_id_dc92224b30"
    t.index ["sector_id"], name: "index_establishment_tracking_sectors_on_sector_id"
  end

  create_table "establishment_trackings", force: :cascade do |t|
    t.bigint "creator_id", null: false
    t.bigint "establishment_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "contact"
    t.datetime "discarded_at"
    t.bigint "size_id"
    t.bigint "criticality_id"
    t.date "modified_at"
    t.index ["creator_id"], name: "index_establishment_trackings_on_creator_id"
    t.index ["criticality_id"], name: "index_establishment_trackings_on_criticality_id"
    t.index ["discarded_at"], name: "index_establishment_trackings_on_discarded_at"
    t.index ["establishment_id", "state"], name: "index_single_in_progress_per_establishment", unique: true, where: "((state)::text = 'in_progress'::text)"
    t.index ["establishment_id"], name: "index_establishment_trackings_on_establishment_id"
    t.index ["size_id"], name: "index_establishment_trackings_on_size_id"
  end

  create_table "establishments", force: :cascade do |t|
    t.text "roles"
    t.string "siret", limit: 14
    t.string "siren", limit: 9
    t.text "raison_sociale"
    t.text "commune"
    t.float "valeur_score"
    t.jsonb "detail_score"
    t.boolean "first_alert"
    t.text "first_list_entreprise"
    t.text "first_red_list_entreprise"
    t.text "first_list_etablissement"
    t.text "first_red_list_etablissement"
    t.text "last_list"
    t.text "last_alert"
    t.text "liste"
    t.float "chiffre_affaire"
    t.float "prev_chiffre_affaire"
    t.date "arrete_bilan"
    t.integer "exercice_diane"
    t.float "variation_ca"
    t.float "resultat_expl"
    t.float "prev_resultat_expl"
    t.float "excedent_brut_d_exploitation"
    t.float "prev_excedent_brut_d_exploitation"
    t.float "effectif"
    t.float "effectif_entreprise"
    t.date "date_entreprise"
    t.date "date_effectif"
    t.text "libelle_n5"
    t.text "libelle_n1"
    t.text "code_activite"
    t.text "last_procol"
    t.date "date_last_procol"
    t.boolean "activite_partielle"
    t.integer "apconso_heure_consomme"
    t.integer "apconso_montant"
    t.boolean "hausse_urssaf"
    t.float "dette_urssaf"
    t.date "periode_urssaf"
    t.boolean "presence_part_salariale"
    t.text "alert"
    t.text "raison_sociale_groupe"
    t.boolean "territoire_industrie"
    t.text "code_territoire_industrie"
    t.text "libelle_territoire_industrie"
    t.text "statut_juridique_n3"
    t.text "statut_juridique_n2"
    t.text "statut_juridique_n1"
    t.datetime "date_ouverture_etablissement", precision: nil
    t.datetime "date_creation_entreprise", precision: nil
    t.text "secteur_covid"
    t.text "etat_administratif"
    t.text "etat_administratif_entreprise"
    t.boolean "has_delai"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "department_id", null: false
    t.bigint "activity_sector_id"
    t.bigint "level_one_activity_sector_id"
    t.bigint "company_id"
    t.boolean "is_siege"
    t.integer "parent_establishment_id"
    t.index ["activity_sector_id"], name: "index_establishments_on_activity_sector_id"
    t.index ["company_id"], name: "index_establishments_on_company_id"
    t.index ["department_id"], name: "index_establishments_on_department_id"
    t.index ["level_one_activity_sector_id"], name: "index_establishments_on_level_one_activity_sector_id"
    t.index ["parent_establishment_id"], name: "index_establishments_on_parent_establishment_id"
    t.index ["siren", "siret"], name: "index_establishments_on_siren_and_siret", unique: true
    t.index ["siret"], name: "index_establishments_on_siret", unique: true
  end

  create_table "geo_accesses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_geo_accesses_on_name", unique: true
  end

  create_table "lists", force: :cascade do |t|
    t.string "label", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "network_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "network_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["network_id"], name: "index_network_memberships_on_network_id"
    t.index ["user_id", "network_id"], name: "index_network_memberships_on_user_id_and_network_id", unique: true
    t.index ["user_id"], name: "index_network_memberships_on_user_id"
  end

  create_table "networks", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "regions", force: :cascade do |t|
    t.string "code", null: false
    t.string "libelle", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
  end

  create_table "sectors", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "segments", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "network_id", null: false
    t.index ["network_id"], name: "index_segments_on_network_id"
  end

  create_table "sizes", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "summaries", force: :cascade do |t|
    t.text "content"
    t.bigint "establishment_tracking_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_codefi", default: false, null: false
    t.integer "locked_by"
    t.datetime "locked_at"
    t.bigint "network_id", null: false
    t.index ["establishment_tracking_id", "is_codefi"], name: "index_summaries_on_establishment_tracking_id_and_is_codefi", unique: true, where: "(is_codefi = true)"
    t.index ["establishment_tracking_id", "network_id"], name: "index_unique_network_summary", unique: true
    t.index ["establishment_tracking_id"], name: "index_summaries_on_establishment_tracking_id"
    t.index ["network_id"], name: "index_summaries_on_network_id"
  end

  create_table "tracking_labels", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "system", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tracking_participants", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "establishment_tracking_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["establishment_tracking_id"], name: "index_tracking_participants_on_establishment_tracking_id"
    t.index ["user_id"], name: "index_tracking_participants_on_user_id"
  end

  create_table "tracking_referents", force: :cascade do |t|
    t.bigint "establishment_tracking_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["establishment_tracking_id"], name: "index_tracking_referents_on_establishment_tracking_id"
    t.index ["user_id"], name: "index_tracking_referents_on_user_id"
  end

  create_table "user_departments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "department_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_user_departments_on_department_id"
    t.index ["user_id"], name: "index_user_departments_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sign_in_count"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "provider"
    t.string "uid"
    t.string "id_token"
    t.string "wekan_document_id"
    t.bigint "entity_id", null: false
    t.bigint "segment_id", null: false
    t.string "level", default: "A", null: false
    t.text "description"
    t.bigint "geo_access_id", null: false
    t.datetime "discarded_at"
    t.string "time_zone"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["entity_id"], name: "index_users_on_entity_id"
    t.index ["geo_access_id"], name: "index_users_on_geo_access_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["segment_id"], name: "index_users_on_segment_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "activity_sectors", "activity_sectors", column: "level_one_id"
  add_foreign_key "activity_sectors", "activity_sectors", column: "parent_id"
  add_foreign_key "campaign_companies", "campaigns"
  add_foreign_key "campaign_companies", "companies"
  add_foreign_key "comments", "establishment_trackings"
  add_foreign_key "comments", "networks"
  add_foreign_key "comments", "users"
  add_foreign_key "companies", "activity_sectors"
  add_foreign_key "companies", "departments"
  add_foreign_key "company_lists", "companies"
  add_foreign_key "company_lists", "lists"
  add_foreign_key "contacts", "establishments"
  add_foreign_key "department_geo_accesses", "departments"
  add_foreign_key "department_geo_accesses", "geo_accesses"
  add_foreign_key "departments", "regions"
  add_foreign_key "establishment_tracking_actions", "actions"
  add_foreign_key "establishment_tracking_actions", "establishment_trackings"
  add_foreign_key "establishment_tracking_labels", "establishment_trackings"
  add_foreign_key "establishment_tracking_labels", "tracking_labels"
  add_foreign_key "establishment_tracking_sectors", "establishment_trackings"
  add_foreign_key "establishment_tracking_sectors", "sectors"
  add_foreign_key "establishment_trackings", "criticalities"
  add_foreign_key "establishment_trackings", "establishments"
  add_foreign_key "establishment_trackings", "sizes"
  add_foreign_key "establishment_trackings", "users", column: "creator_id"
  add_foreign_key "establishments", "activity_sectors"
  add_foreign_key "establishments", "activity_sectors", column: "level_one_activity_sector_id"
  add_foreign_key "establishments", "companies"
  add_foreign_key "establishments", "departments"
  add_foreign_key "establishments", "establishments", column: "parent_establishment_id"
  add_foreign_key "network_memberships", "networks"
  add_foreign_key "network_memberships", "users"
  add_foreign_key "segments", "networks"
  add_foreign_key "summaries", "establishment_trackings"
  add_foreign_key "summaries", "networks"
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
