require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:user_crp_paris)
  end

  test "non_codefi_network should return the non-CODEFI network" do
    assert_equal networks(:network_crp), @user.non_codefi_network
  end

  test "password_complexity adds localized error for weak password" do
    user = users(:user_crp_paris)
    user.password = "short"
    user.password_confirmation = "short"

    assert_not user.valid?
    assert_includes user.errors[:password],
                    I18n.t("activerecord.errors.models.user.attributes.password.complexity")
  end
end
