require 'test_helper'

class UserAuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    # Create necessary test data (users, tokens, etc.)
    @region = Region.create!(libelle: 'Île-de-France')
    @geo_access = GeoAccess.create!(name: 'Île-de-France')
    @departments = [
      Department.create!(code: '75', name: 'Paris', region: @region),
      Department.create!(code: '78', name: 'Yvelines', region: @region)
    ]
    @user = User.create!(email: 'test@example.com', password: 'password', geo_access: @geo_access, departments: @departments)

    # Generate a token for the user (replace this with your JWT token logic)
    token_payload = {
      'email' => @user.email,
      'first_name' => @user.first_name,
      'last_name' => @user.last_name
    }
    @token = JWT.encode(token_payload, nil, 'none')
  end

  test 'user can authenticate via token and access the homepage' do
    # Make a POST request to authenticate the user
    post '/users/sign_in', params: { token: @token }

    # Check if the user was successfully authenticated (response success)
    assert_response :success
    assert_includes @response.body, 'success'

    # Simulate a follow-up request where the user should be authenticated
    get root_path

    # Assert that the user can access the homepage (ensure they are redirected if necessary)
    assert_response :success
    assert_includes @response.body, 'Accueil de l\'application'
  end
end