class RemoveLabelGroupReferenceFromTrackingLabels < ActiveRecord::Migration[7.1]
  def change
    remove_reference :tracking_labels, :label_group, foreign_key: true
  end
end
