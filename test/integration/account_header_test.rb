# frozen_string_literal: true

require "test_helper"

# The chrome that says who is signed in, and the way back in when nobody is.
# Opening the menu is covered by test/system/account_menu_test.rb - a request test cannot
# tell an open disclosure from a closed one.
class AccountHeaderTest < ActionDispatch::IntegrationTest
  MENU = "[data-testid='account-menu']"

  test "the signed-out header offers a way in" do
    get new_user_password_path

    assert_response :success
    assert_select "header a[href=?]", new_user_session_path, text: "Sign in"
    assert_select "header img[alt=?]", "Stocks in The Future"
  end

  test "the sign-in page does not offer a link to itself" do
    get new_user_session_path

    assert_response :success
    assert_select "header img[alt=?]", "Stocks in The Future"
    assert_select "header a", text: "Sign in", count: 0
  end

  test "a signed-in student sees their name, role and initial in the header" do
    student = create(:student, :with_portfolio, username: "finn")
    sign_in(student)

    get root_path

    assert_response :success
    assert_select "#{MENU} summary", text: /finn/
    assert_select MENU, text: /Student/
    # Initials are aria-hidden, so they must not be the only carrier of the name.
    assert_select "#{MENU} span[aria-hidden='true']", text: "F"
    assert_select "#{MENU} .sr-only", text: "Account menu"
  end

  test "the menu carries sign out, and the sidebar no longer does" do
    sign_in(create(:student, :with_portfolio))

    get root_path

    assert_select "#{MENU} a[href=?]", destroy_user_session_path, count: 1
    assert_select "nav[aria-label='Main'] a[href=?]", destroy_user_session_path, count: 0
  end

  test "the admin layout renders the same menu" do
    sign_in(create(:admin))

    get admin_classrooms_path

    assert_response :success
    assert_select MENU, text: /Admin/
    assert_select "#{MENU} a[href=?]", root_path, text: "View site"
    assert_select "#{MENU} a[href=?]", destroy_user_session_path
  end

  test "a teacher's menu shows the teacher role" do
    teacher = create(:teacher, username: "mrs_smith")
    sign_in(teacher)

    get root_path

    assert_response :success
    assert_select MENU, text: /Teacher/
  end
end
