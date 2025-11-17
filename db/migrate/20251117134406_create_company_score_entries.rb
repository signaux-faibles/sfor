class CreateCompanyScoreEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :company_score_entries do |t|
      # Foreign keys
      t.references :company, null: false, foreign_key: true
      t.references :list, null: false, foreign_key: true
      
      # Simple fields from JSON
      t.string :siren, limit: 9, null: false
      t.string :code_naf
      t.decimal :score, precision: 20, scale: 10
      t.string :code_commune, limit: 5
      t.string :region
      t.string :alert
      t.string :batch
      t.string :algo
      t.string :periode
      t.decimal :seuil_modere, precision: 5, scale: 2
      t.decimal :seuil_fort, precision: 5, scale: 2
      
      # JSONB columns for nested data
      t.jsonb :macro_expl
      t.jsonb :micro_expl
      
      t.timestamps
    end
    
    # Indexes for performance
    add_index :company_score_entries, :siren
    add_index :company_score_entries, :code_commune
    add_index :company_score_entries, :periode
    add_index :company_score_entries, [:company_id, :list_id, :periode]
    add_index :company_score_entries, :macro_expl, using: :gin
    add_index :company_score_entries, :micro_expl, using: :gin
  end
end
