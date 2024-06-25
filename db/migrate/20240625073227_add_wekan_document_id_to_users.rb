class AddWekanDocumentIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :wekan_document_id, :string
  end
end
