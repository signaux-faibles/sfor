require "test_helper"

class SentryContainerContextTest < ActiveSupport::TestCase
  test "uses web role by default" do
    assert_equal "web", SentryContainerContext.role(program_name: "bin/rails", argv: [], env: {})
  end

  test "detects solid queue worker from bin/jobs" do
    assert_equal "worker", SentryContainerContext.role(program_name: "bin/jobs", argv: [], env: {})
  end

  test "detects solid queue worker from arguments" do
    assert_equal "worker", SentryContainerContext.role(program_name: "bin/rails", argv: ["solid_queue:start"], env: {})
  end

  test "uses explicit container role when configured" do
    assert_equal "worker", SentryContainerContext.role(program_name: "bin/rails", argv: [], env: {
      "SENTRY_CONTAINER_ROLE" => "worker"
    })
  end
end
