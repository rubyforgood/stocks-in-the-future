# frozen_string_literal: true

require "test_helper"

# One endpoint for every dismissible banner, which makes the key allowlist the security boundary:
# without it this is a write of arbitrary strings into a table, keyed by whatever a client sends.
class DismissalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = create(:student, :with_portfolio, classroom: create(:classroom, trading_enabled: false))
    @student.reload
  end

  test "a known key is recorded" do
    sign_in @student

    assert_difference -> { Dismissal.count }, 1 do
      post dismissals_path, params: { key: Dismissal::TRADING_OFF }
    end

    assert @student.dismissed?(Dismissal::TRADING_OFF)
  end

  test "an unknown key is refused and writes nothing" do
    sign_in @student

    assert_no_difference -> { Dismissal.count } do
      post dismissals_path, params: { key: "anything_i_like" }
    end

    assert_response :bad_request
  end

  test "a missing key is refused" do
    sign_in @student

    assert_no_difference -> { Dismissal.count } do
      post dismissals_path
    end

    assert_response :bad_request
  end

  # The dismissal is always written for current_user, so there is no id in the request to tamper with -
  # but it must still require somebody to be signed in.
  test "signed out writes nothing" do
    assert_no_difference -> { Dismissal.count } do
      post dismissals_path, params: { key: Dismissal::TRADING_OFF }
    end

    assert_redirected_to new_user_session_path
  end

  test "one user cannot dismiss for another" do
    other = create(:student, :with_portfolio, classroom: @student.classroom)
    sign_in @student

    post dismissals_path, params: { key: Dismissal::TRADING_OFF, user_id: other.id }

    assert @student.dismissed?(Dismissal::TRADING_OFF)
    assert_not other.reload.dismissed?(Dismissal::TRADING_OFF)
  end

  test "it returns to the page the banner was on" do
    sign_in @student

    post dismissals_path,
         params: { key: Dismissal::TRADING_OFF },
         headers: { "HTTP_REFERER" => stocks_url }

    assert_redirected_to stocks_url
  end
end
