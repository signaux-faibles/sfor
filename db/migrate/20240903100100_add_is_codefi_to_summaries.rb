class AddIsCodefiToSummaries < ActiveRecord::Migration[7.1]
  def change
    add_column :summaries, :is_codefi, :boolean, default: false, null: false
    add_index :summaries, [:establishment_tracking_id, :is_codefi], unique: true, where: "is_codefi = true"
  end
end
