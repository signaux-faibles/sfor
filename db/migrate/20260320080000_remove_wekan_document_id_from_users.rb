class RemoveWekanDocumentIdFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :wekan_document_id, :string
  end
end