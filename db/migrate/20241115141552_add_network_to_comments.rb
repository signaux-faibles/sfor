class AddNetworkToComments < ActiveRecord::Migration[7.1]
  def change
    add_reference :comments, :network, null: false, foreign_key: true
  end
end
