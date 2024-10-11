module EstablishmentTrackingsHelper
  def grouped_labels_for_select
    LabelGroup.includes(:tracking_labels).map do |group|
      [group.name, group.tracking_labels.pluck(:name, :id)]
    end
  end
end