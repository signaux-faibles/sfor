require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @establishment_tracking = establishment_trackings(:establishment_tracking_paris)
    @establishment = @establishment_tracking.establishment

    @user_a = users(:user_crp_paris)
    @user_b = users(:user_crp_paris_2)

    @establishment_tracking.referents << [@user_a, @user_b]

    @comment = comments(:comment_paris_crp)
  end

  test "user A can create a comment" do
    sign_in @user_a

    assert_difference('Comment.count', 1) do
      post establishment_establishment_tracking_comments_path(@establishment, @establishment_tracking),
           params: { comment: { content: "This is a new comment", network_id: @user_a.networks.where.not(name: 'codefi').first.id } },
           as: :turbo_stream
    end

    assert_response :success
    assert_includes @response.body, "Commentaire ajouté avec succès."
  end

  test "user A can edit their comment" do
    sign_in @user_a

    get edit_establishment_establishment_tracking_comment_path(@establishment, @establishment_tracking, @comment),
        as: :turbo_stream

    assert_response :success
    assert_includes @response.body, @comment.content
  end

  test "user B cannot edit a comment created by user A" do
    sign_in @user_b


    get edit_establishment_establishment_tracking_comment_path(@establishment, @establishment_tracking, @comment),
        as: :turbo_stream

    assert_response :forbidden
  end

  test "user A can update their comment" do
    sign_in @user_a

    patch establishment_establishment_tracking_comment_path(@establishment, @establishment_tracking, @comment),
          params: { comment: { content: "Updated comment content" } },
          as: :turbo_stream

    @comment.reload
    assert_equal "Updated comment content", @comment.content
    assert_includes @response.body, "Commentaire mis à jour avec succès."
  end

  test "user A can delete their comment" do
    sign_in @user_a

    assert_difference('Comment.count', -1) do
      delete establishment_establishment_tracking_comment_path(@establishment, @establishment_tracking, @comment),
             as: :turbo_stream
    end

    assert_response :success
    assert_includes @response.body, "Commentaire supprimé avec succès."
  end

  test "user B cannot delete a comment created by user A" do
    sign_in @user_b

    assert_no_difference('Comment.count') do
      delete establishment_establishment_tracking_comment_path(@establishment, @establishment_tracking, @comment),
             as: :turbo_stream
    end

    assert_response :forbidden
  end

  test "user A sees the comment form for their network" do
    sign_in @user_a

    get establishment_establishment_tracking_path(@establishment, @establishment_tracking)

    @user_a.networks.each do |network|
      assert_select "form[action=?]", establishment_establishment_tracking_comments_path(@establishment, @establishment_tracking)
      assert_select "input[type=hidden][value=?]", network.id.to_s
    end
  end
end