require "test_helper"

class EstablishmentTrackingTest < ActiveSupport::TestCase
  test "sets modified_at on creation" do
    tracking = EstablishmentTracking.create!(
      establishment: establishments(:establishment_paris_no_trackings),
      creator: users(:user_crp_paris),
      referents: [users(:user_crp_paris)]
    )

    assert_equal Date.current, tracking.modified_at
  end

  test "updates modified_at when a comment is added" do
    tracking = establishment_trackings(:establishment_tracking_paris)
    original_modified_at = tracking.modified_at

    tracking.comments.create!(
      user: users(:user_crp_paris),
      content: "This is a test comment",
      network: networks(:network_crp)
    )

    tracking.reload

    assert_not_equal original_modified_at, tracking.modified_at
    assert_equal Date.current, tracking.modified_at
  end

  test "updates modified_at when a summary is added or updated" do
    tracking = establishment_trackings(:establishment_tracking_paris_no_content)
    original_modified_at = tracking.modified_at

    tracking.summaries.create!(
      network: networks(:network_crp),
      content: "Initial summary content",
    )
    tracking.reload
    assert_not_equal original_modified_at, tracking.modified_at
    assert_equal Date.current, tracking.modified_at

    summary = tracking.summaries.last
    summary.update!(content: "Updated summary content")
    tracking.reload
    assert_equal Date.current, tracking.modified_at
  end

  test "updates modified_at when criticality is changed" do
    tracking = establishment_trackings(:establishment_tracking_paris)
    original_modified_at = tracking.modified_at

    tracking.update!(criticality: criticalities(:niveau_orange))
    tracking.reload
    assert_not_equal original_modified_at, tracking.modified_at
    assert_equal Date.current, tracking.modified_at
  end

  test "cannot create a new tracking if one is in_progress or under_surveillance" do
    establishment = establishments(:establishment_paris_no_trackings)

    establishment.establishment_trackings.create!(
      state: 'in_progress',
      creator: users(:user_crp_paris),
      referents: [users(:user_crp_paris)]
    )

    new_tracking = establishment.establishment_trackings.new(
      state: 'in_progress',
      creator: users(:user_crp_paris),
      referents: [users(:user_crp_paris)]
    )

    # Validate the new tracking is invalid
    assert_not new_tracking.valid?
    assert_includes new_tracking.errors[:state], 'Un accompagnement "en cours" ou "sous surveillance" existe déjà pour cet établissement.'
  end
end
