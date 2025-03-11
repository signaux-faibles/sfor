class CreateCodefiRedirects < ActiveRecord::Migration[7.1]
  def change
    create_table :codefi_redirects do |t|
      t.string :name

      t.timestamps
    end
  end
end
