# frozen_string_literal: true

require "test_helper"

class NavbarPolicyVisibilityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    classroom = create(:classroom)
    @student = User.create!(username: "student", type: "Student", password: "password", classroom: classroom)
    @teacher = User.create!(username: "teacher", type: "Teacher", password: "password", email: "teacher@test.com")
    @admin = User.create!(username: "admin", type: "Teacher", admin: true, password: "password",
                          email: "admin@test.com")
    @portfolio = Portfolio.create!(user: @student)
  end

  test "student sees My Portfolio if permitted" do
    sign_in @student
    get root_path
    assert_select "a", text: "My Portfolio"
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
end
