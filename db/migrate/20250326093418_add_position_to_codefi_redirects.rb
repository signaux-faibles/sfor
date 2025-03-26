class AddPositionToCodefiRedirects < ActiveRecord::Migration[7.1]
  def change
    add_column :codefi_redirects, :position, :integer, null: false, default: 0
  end
end
