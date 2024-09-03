class AddIsCodefiToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :is_codefi, :boolean, default: false, null: false
  end
end
