class AddNetworkToSummaries < ActiveRecord::Migration[7.1]
  def change
    add_reference :summaries, :network, null: false, foreign_key: true
  end
end
