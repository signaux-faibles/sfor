class CreateInpiBceRatios < ActiveRecord::Migration[7.2]
  def change # rubocop:disable Metrics/MethodLength
    create_table :inpi_bce_ratios do |t|
      t.string :siren, limit: 9, null: false
      t.date :date_cloture_exercice, null: false
      t.bigint :chiffre_d_affaires
      t.bigint :marge_brute
      t.bigint :ebe
      t.bigint :ebit
      t.bigint :resultat_net
      t.decimal :taux_d_endettement, precision: 20, scale: 6
      t.decimal :ratio_de_liquidite, precision: 20, scale: 6
      t.decimal :ratio_de_vetuste, precision: 20, scale: 6
      t.decimal :autonomie_financiere, precision: 20, scale: 6
      t.decimal :poids_bfr_exploitation_sur_ca, precision: 20, scale: 6
      t.decimal :couverture_des_interets, precision: 20, scale: 6
      t.decimal :caf_sur_ca, precision: 20, scale: 6
      t.decimal :capacite_de_remboursement, precision: 20, scale: 6
      t.decimal :marge_ebe, precision: 20, scale: 6
      t.decimal :resultat_courant_avant_impots_sur_ca, precision: 20, scale: 6
      t.decimal :poids_bfr_exploitation_sur_ca_jours, precision: 20, scale: 6
      t.decimal :rotation_des_stocks_jours, precision: 20, scale: 6
      t.decimal :credit_clients_jours, precision: 20, scale: 6
      t.decimal :credit_fournisseurs_jours, precision: 20, scale: 6
      t.string :type_bilan, limit: 1, null: false
      t.string :confidentiality

      t.timestamps
    end

    add_index :inpi_bce_ratios, :siren
    add_index :inpi_bce_ratios,
              %i[siren date_cloture_exercice type_bilan],
              unique: true,
              name: "idx_inpi_bce_ratios_unique_period_type"
    add_index :inpi_bce_ratios,
              %i[siren date_cloture_exercice],
              name: "idx_inpi_bce_ratios_latest_by_siren"
  end
end
