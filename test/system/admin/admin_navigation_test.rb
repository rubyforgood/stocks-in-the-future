# frozen_string_literal: true

require "application_system_test_case"

module Admin
  class AdminNavigationTest < ApplicationSystemTestCase
    setup do
      @admin = create(:admin)
      sign_in @admin
    end

    test "admin navigation does not show School Years link" do
      visit admin_root_path

      assert_link "School Years"
      assert_link "Announcements"
      assert_link "Classrooms"
      assert_link "Schools"
      assert_link "Stocks"
      assert_link "Students"
      assert_link "Teachers"
      assert_link "Users"
      assert_link "Years"
    end
  end
end
