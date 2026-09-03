require "test_helper"
require "open3"

class ActiveRecordEncryptionBootTest < ActiveSupport::TestCase
  test "production boot with SECRET_KEY_BASE_DUMMY does not require encryption keys" do
    stdout, stderr, status = boot_application(
      "RAILS_ENV" => "production",
      "SECRET_KEY_BASE_DUMMY" => "1",
      "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY" => nil,
      "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY" => nil,
      "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT" => nil
    )

    assert_predicate status, :success?, stderr
    assert_includes stdout, "booted"
  end

  test "production boot without dummy requires encryption keys" do
    _stdout, stderr, status = boot_application(
      "RAILS_ENV" => "production",
      "SECRET_KEY_BASE_DUMMY" => nil,
      "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY" => nil,
      "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY" => nil,
      "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT" => nil
    )

    assert_not_predicate status, :success?
    assert_includes stderr, "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"
  end

  private

  def boot_application(env)
    Open3.capture3(
      env,
      "bundle",
      "exec",
      "ruby",
      "-e",
      "require_relative 'config/application'; puts 'booted'",
      chdir: Rails.root.to_s
    )
  end
end
