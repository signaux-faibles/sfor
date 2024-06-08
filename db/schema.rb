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

ActiveRecord::Schema[7.1].define(version: 2024_06_08_200613) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campaign_memberships", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "establishment_id", null: false
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_campaign_memberships_on_campaign_id"
    t.index ["establishment_id"], name: "index_campaign_memberships_on_establishment_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "departments", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "establishments", force: :cascade do |t|
    t.text "roles"
    t.string "siret", limit: 14
    t.string "siren", limit: 9
    t.text "raison_sociale"
    t.text "commune"
    t.text "libelle_departement"
    t.text "code_departement"
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
    t.integer "parent_company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "department_id", null: false
    t.index ["department_id"], name: "index_establishments_on_department_id"
    t.index ["parent_company_id"], name: "index_establishments_on_parent_company_id"
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "campaign_memberships", "campaigns"
  add_foreign_key "campaign_memberships", "establishments"
  add_foreign_key "establishments", "departments"
end
