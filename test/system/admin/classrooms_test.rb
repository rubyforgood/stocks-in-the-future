# frozen_string_literal: true

require "application_system_test_case"

module Admin
  class ClassroomsTest < ApplicationSystemTestCase
    setup do
      @admin = create(:admin)
      sign_in @admin
      @classroom = create(:classroom)
    end

    test "admin can archive classroom" do
      visit admin_classroom_url(@classroom)
      assert_text @classroom.name

      accept_confirm { click_on "Archive" }

      assert_text "Classroom has been archived"
      assert_current_path admin_classrooms_path
    end

    test "admin can activate archived classroom" do
      @classroom.update!(archived: true)

      visit admin_classroom_url(@classroom)
      assert_text @classroom.name

      accept_confirm { click_on "Activate" }

      assert_text "Classroom has been activated"
      assert_current_path admin_classrooms_path
    end

    test "destroy button does not appear" do
      visit admin_classroom_url(@classroom)

      assert_no_button "Destroy"
    end
  end
end
