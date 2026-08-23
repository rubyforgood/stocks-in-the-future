# frozen_string_literal: true

require "test_helper"

class NavbarPolicyVisibilityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    classroom = create(:classroom)
    @student = User.create!(username: "student", type: "Student", password: "password", classroom: classroom)
    @teacher = User.create!(username: "teacher", type: "Teacher", password: "password", email: "teacher@test.com")
    @admin = User.create!(
      username: "admin", type: "Teacher", admin: true, password: "password",
      email: "admin@test.com"
    )
    @portfolio = Portfolio.create!(user: @student)
  end

  test "student sees My Portfolio if permitted" do
    sign_in @student
    get root_path
    assert_select "a", text: "My portfolio"
  end

  test "teacher sees Classes if permitted" do
    sign_in @teacher
    get root_path
    assert_select "a", text: "Classes"
  end

  test "admin sees Admin if permitted" do
    sign_in @admin
    get root_path
    assert_select "a", text: "Admin"
  end

  # The four tests that used to live here asserted on the per-stock sublist under the Trading
  # floor disclosure - which stocks a student could see in the *navigation*. The nav is one
  # level deep now (migration.md, Map A), so that subject moved to the trading floor page in
  # stocks_controller_test, where the catalogue actually lives. It was not deleted: the page
  # gives it a better home, since the page distinguishes active from archived rather than
  # hiding archived entirely.
  test "the trading floor is a flat nav row with no stock sublist" do
    create(:stock, archived: false, ticker: "AAPL")
    sign_in @student

    get root_path

    assert_select "nav[aria-label='Main']" do
      assert_select "a", text: "Trading floor"
      assert_select "details", count: 0
      assert_select "a[href=?]", stock_path(Stock.find_by!(ticker: "AAPL")), count: 0
    end
  end
end
