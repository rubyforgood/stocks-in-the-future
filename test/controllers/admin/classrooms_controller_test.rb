# frozen_string_literal: true

require "test_helper"

module Admin
  class ClassroomsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin)
      sign_in @admin
      @classroom = create(:classroom)
    end

    test "should get index" do
      get admin_classrooms_url
      assert_response :success
    end

    test "should get new" do
      get new_admin_classroom_url
      assert_response :success
    end

    test "should create classroom" do
      school_year = create(:school_year)
      assert_difference("Classroom.count") do
        post admin_classrooms_url, params: {
          classroom: {
            name: "New Classroom",
            grade: 9,
            school_year_id: school_year.id
          }
        }
      end

      assert_redirected_to admin_classroom_url(Classroom.last)
    end

    test "should show classroom" do
      get admin_classroom_url(@classroom)
      assert_response :success
    end

    test "should get edit" do
      get edit_admin_classroom_url(@classroom)
      assert_response :success
    end

    test "should update classroom" do
      patch admin_classroom_url(@classroom),
            params: { classroom: { name: "Updated Classroom" } }
      assert_redirected_to admin_classroom_url(@classroom)
    end

    test "should not allow destroy" do
      delete admin_classroom_url(@classroom)
      assert_response :not_found
    end

    test "should archive classroom via toggle_archive" do
      assert_not @classroom.archived?

      patch toggle_archive_admin_classroom_url(@classroom)

      @classroom.reload
      assert @classroom.archived?
      assert_redirected_to admin_classrooms_url
      assert_equal "Classroom has been archived.", flash[:notice]
    end

    test "should activate classroom via toggle_archive" do
      @classroom.update!(archived: true)
      assert @classroom.archived?

      patch toggle_archive_admin_classroom_url(@classroom)

      @classroom.reload
      assert_not @classroom.archived?
      assert_redirected_to admin_classrooms_url
      assert_equal "Classroom has been activated.", flash[:notice]
    end

    test "non-admin users cannot access admin classrooms" do
      sign_out @admin
      teacher = create(:teacher)
      sign_in teacher

      get admin_classrooms_url
      assert_response :redirect
      assert_redirected_to root_url
    end
  end
end
