require 'test_helper'

class ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @establishment_tracking = establishment_trackings(:establishment_tracking_paris)
    @establishment = @establishment_tracking.establishment

    @user_a = users(:user_crp_paris)

    @contact = contacts(:one)
  end

  test "user A can view sorted list of contacts" do
    sign_in @user_a

    get establishment_establishment_tracking_path(@establishment, @establishment_tracking)

    assert_select "h4", text: "#{@contact.first_name} #{@contact.last_name}"
  end

  test "user A can create a new contact" do
    sign_in @user_a

    assert_difference('Contact.count', 1) do
      post establishment_establishment_tracking_contacts_path(@establishment, @establishment_tracking),
           params: { contact: { first_name: "New", last_name: "Contact", role: "Director", phone_number_primary: "1234567890" } },
           as: :turbo_stream
    end

    assert_redirected_to establishment_establishment_tracking_path(@establishment, @establishment_tracking)
    follow_redirect!
    assert_response :success
    assert_includes @response.body, 'Contact créé avec succès.'
  end

  test "user A can edit an existing contact" do
    sign_in @user_a

    get edit_establishment_establishment_tracking_contact_path(@establishment, @establishment_tracking, @contact), as: :turbo_stream

    assert_response :success
    assert_includes @response.body, @contact.first_name
  end

  test "user A can update a contact" do
    sign_in @user_a

    patch establishment_establishment_tracking_contact_path(@establishment, @establishment_tracking, @contact),
          params: { contact: { first_name: "Updated", last_name: "Name" } },
          as: :turbo_stream

    @contact.reload
    assert_equal "Updated", @contact.first_name
    assert_redirected_to establishment_establishment_tracking_path(@establishment, @establishment_tracking)
    follow_redirect!
    assert_response :success
    assert_includes @response.body, "Contact mis à jour avec succès."
  end
end