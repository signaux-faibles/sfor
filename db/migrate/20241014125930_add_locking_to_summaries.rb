class AddLockingToSummaries < ActiveRecord::Migration[7.1]
  def change
    add_column :summaries, :locked_by, :integer
    add_column :summaries, :locked_at, :datetime
  end
end
