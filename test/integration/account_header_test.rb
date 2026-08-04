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

  test "the trigger is initials and a chevron, and names the user for assistive tech" do
    student = create(:student, :with_portfolio, username: "finn")
    sign_in(student)

    get root_path

    assert_response :success
    # Initials are aria-hidden, so the sr-only text is the control's whole accessible name - and
    # it has to say whose account, because the visible trigger is now initials only.
    assert_select "#{MENU} span[aria-hidden='true']", text: "F"
    assert_select "#{MENU} .sr-only", text: "Account menu for finn"
    # The name is not printed beside the avatar any more; it lives in the panel.
    assert_select "#{MENU} summary span:not(.sr-only)", text: /finn/, count: 0
  end

  test "the panel carries name, email and role" do
    student = create(:student, :with_portfolio, username: "finn", email: "finn@example.com")
    sign_in(student)

    get root_path

    assert_select MENU, text: /finn/
    assert_select MENU, text: /finn@example.com/
    assert_select MENU, text: /Student/
  end

  test "a user with no email gets no blank line" do
    student = create(:student, :with_portfolio, username: "finn", email: nil)
    sign_in(student)

    get root_path

    assert_select MENU, text: /finn/
    assert_select "#{MENU} p", text: "", count: 0
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
    assert_select "#{MENU} a[href=?]", destroy_user_session_path
  end

  test "the way back to the site is a top-bar control, not an account action" do
    sign_in(create(:admin))

    get admin_classrooms_path

    # A destination behind an avatar is not discoverable, so it sits in persistent chrome - where
    # WordPress and Django both keep it. Not the sidebar: a footer row there pushed the admin nav
    # 68px past a Chromebook, which spacing_test caught.
    assert_select "#{MENU} a[href=?]", root_path, count: 0
    assert_select "nav[aria-label='Admin'] a[href=?]", root_path, count: 0
    assert_select "body > div.fixed a[href=?]", root_path, text: /View site/
  end

  test "the account menu holds no navigation on the app side either" do
    student = create(:student, :with_portfolio)
    sign_in(student)

    get root_path

    # "My portfolio" was a second copy of a row the sidebar already carries.
    assert_select "#{MENU} a[href=?]", user_portfolio_path(student, student.portfolio), count: 0
    assert_select "nav[aria-label='Main'] a[href=?]",
                  user_portfolio_path(student, student.portfolio), count: 1
  end

  test "a teacher's menu shows the teacher role" do
    teacher = create(:teacher, username: "mrs_smith")
    sign_in(teacher)

    get root_path

    assert_response :success
    assert_select MENU, text: /Teacher/
  end
end
