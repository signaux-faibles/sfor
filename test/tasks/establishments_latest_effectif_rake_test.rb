# frozen_string_literal: true

require "test_helper"
require "rake"

class EstablishmentsLatestEffectifRakeTest < ActiveSupport::TestCase
  setup do
    Rake.application.rake_require "tasks/establishments_latest_effectif"
    Rake::Task.define_task(:environment)
    @task = Rake::Task["establishments:update_latest_effectif"]
  end

  teardown do
    @task.reenable
  end

  test "update_latest_effectif copies effectif from latest osf_effectifs row" do
    establishment = establishments(:establishment_paris2)
    assert_nil establishment.latest_effectif

    @task.invoke

    assert_equal 99, establishment.reload.latest_effectif
  end
end
