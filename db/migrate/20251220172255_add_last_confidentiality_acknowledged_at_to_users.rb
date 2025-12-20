class AddLastConfidentialityAcknowledgedAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :last_confidentiality_acknowledged_at, :datetime
  end
end

