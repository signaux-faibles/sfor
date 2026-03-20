# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  setup do
    @admin = users(:user_admin_sf)
    @non_admin = users(:user_crp_paris)
    @target_user = users(:user_crp_paris2)
  end

  test "index redirects non admin" do
    sign_in @non_admin

    get admin_users_path

    assert_redirected_to root_url
  end

  test "index renders for admin" do
    sign_in @admin

    get admin_users_path

    assert_response :success
    assert_includes @response.body, "Gestion des utilisateurs"
  end

  test "create user" do
    sign_in @admin

    assert_difference("User.count", 1) do
      post admin_users_path, params: {
        user: {
          email: "new-user@example.com",
          first_name: "Nina",
          last_name: "Dupont",
          segment_id: segments(:segment_crp).id,
          geo_access_id: geo_accesses(:geo_access_paris).id,
          entity_id: entities(:entity_dreets).id,
          description: "Profil créé par admin",
          ambassador: true,
          trained: false,
          feedbacks: "RAS",
          last_contact: "2026-02-01"
        }
      }
    end

    assert_redirected_to admin_user_path(User.find_by!(email: "new-user@example.com"))
  end

  test "update user" do
    sign_in @admin

    patch admin_user_path(@target_user), params: {
      user: {
        first_name: "Updated",
        ambassador: true,
        trained: true
      }
    }

    assert_redirected_to admin_user_path(@target_user)
    @target_user.reload
    assert_equal "Updated", @target_user.first_name
    assert_equal true, @target_user.ambassador
    assert_equal true, @target_user.trained
  end

  test "discard user" do
    sign_in @admin

    delete discard_admin_user_path(@target_user)

    assert_redirected_to admin_users_path
    assert_predicate @target_user.reload, :discarded?
  end

  test "restore user" do
    sign_in @admin

    @target_user.discard
    patch restore_admin_user_path(@target_user)

    assert_redirected_to admin_user_path(@target_user)
    assert_not @target_user.reload.discarded?
  end

  test "duplicate renders prefilled form without identity" do
    sign_in @admin

    @target_user.update!(
      description: "Description test",
      ambassador: true,
      trained: true,
      feedbacks: "Retour test",
      last_contact: Date.new(2026, 2, 1)
    )

    get duplicate_admin_user_path(@target_user)

    assert_response :success
    assert_not_includes @response.body, "Description test"
    assert_not_includes @response.body, "Retour test"
    assert_not_includes @response.body, @target_user.email
  end

  test "import creates users and reports failures" do
    sign_in @admin

    csv_content = <<~CSV
      email,first_name,last_name,segment_name,geo_access,entity,description,ambassador,trained,feedbacks,last_contact
      import1@example.com,Jean,Martin,crp,Paris,DREETS,Test,oui,non,Notes,2026-02-10
      test2@crp_paris.com,Duplicate,User,crp,Paris,DREETS,Test,oui,non,Notes,2026-02-10
    CSV

    file = Tempfile.new(["users", ".csv"])
    file.write(csv_content)
    file.rewind

    uploaded = Rack::Test::UploadedFile.new(file.path, "text/csv")

    assert_difference("User.count", 1) do
      post import_admin_users_path, params: { csv_file: uploaded }
    end

    assert_response :success
    assert_includes @response.body, "Utilisateurs créés :</strong> 1"
    assert_includes @response.body, "Utilisateurs non créés :</strong> 1"
  ensure
    file.close
    file.unlink
  end

  test "template downloads csv" do
    sign_in @admin

    get template_admin_users_path

    assert_response :success
    assert_equal "text/csv", @response.media_type
    assert_includes @response.body, "email,first_name,last_name,segment_name,geo_access,entity,description,ambassador,trained,feedbacks,last_contact"
  end

  test "export downloads csv" do
    sign_in @admin

    get export_admin_users_path

    assert_response :success
    assert_equal "text/csv", @response.media_type
    assert_includes @response.body, "email"
    assert_includes @response.body, "entity_name"
    assert_includes @response.body, "segment_name"
    assert_includes @response.body, "geo_access_name"
    assert_not_includes @response.body, "encrypted_password"
    assert_not_includes @response.body, "reset_password_token"
    assert_not_includes @response.body, "entity_id"
    assert_not_includes @response.body, "segment_id"
    assert_not_includes @response.body, "level"
    assert_not_includes @response.body, "geo_access_id"
  end
end
