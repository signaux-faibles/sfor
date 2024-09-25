require 'test_helper'

class UserAuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @region = Region.create!(libelle: 'Île-de-France', code: '11')
    @entity = Entity.create!(name: 'Une entité CRP')
    @segment = Segment.create!(name: 'crp')
    @geo_access = GeoAccess.create!(name: 'Île-de-France')
    @departments = [
      Department.create!(code: '75', name: 'Paris', region: @region),
      Department.create!(code: '78', name: 'Yvelines', region: @region)
    ]
    @user = User.create!(email: 'test@example.com', password: 'password', geo_access: @geo_access, departments: @departments, entity: @entity, segment: @segment)

    token_payload = {
      'email' => @user.email,
      'first_name' => @user.first_name,
      'last_name' => @user.last_name
    }
    @token = JWT.encode(token_payload, nil, 'none')
  end

  test 'user can authenticate via token and access the homepage' do
    # Simulating what happens when logging from Vue js app
    post '/users/sign_in', params: { token: @token }

    assert_response :success
    assert_includes @response.body, 'success'

    # Simulate the redirect which is actyally done by Vue js
    get root_path

    assert_response :success
    assert_includes @response.body, 'Accueil de l\'application'
  end
end


