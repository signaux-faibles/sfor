class AddLabelGroupToTrackingLabels < ActiveRecord::Migration[7.1]
  def change
    add_reference :tracking_labels, :label_group, null: true, foreign_key: true
  end
end
