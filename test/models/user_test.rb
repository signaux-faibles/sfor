require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:user_crp_paris)
  end

  test "non_codefi_network should return the non-CODEFI network" do
    assert_equal networks(:network_crp), @user.non_codefi_network
  end
end