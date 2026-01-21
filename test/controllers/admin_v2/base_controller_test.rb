# frozen_string_literal: true

require "test_helper"

module Admin
  module V2
    class BaseControllerTest < ActionDispatch::IntegrationTest
      test "admin can access admin v2 dashboard" do
        admin = create(:admin, admin: true)
        sign_in(admin)

        get admin_v2_root_path

        assert_response :success
      end

      test "non-admin cannot access admin v2 dashboard" do
        teacher = create(:teacher)
        sign_in(teacher)

        get admin_v2_root_path

        assert_redirected_to root_path
        assert_equal "Access denied. Admin privileges required.", flash[:alert]
      end

      test "unauthenticated user redirected to sign in" do
        get admin_v2_root_path

        assert_redirected_to new_user_session_path
      end
    end

    # Test apply_sorting helper method via integration tests
    # Note: sorting is tested through actual HTTP requests to the grades endpoint
    # since apply_sorting is a private helper method
    class ApplySortingTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:admin, admin: true)
        sign_in(@admin)

        # Create test data
        @grade1 = create(:grade, name: "First Grade", level: 1)
        @grade2 = create(:grade, name: "Second Grade", level: 2)
        @grade3 = create(:grade, name: "Kindergarten", level: 0)
      end

      test "sorts by default column when no params" do
        get admin_v2_grades_path

        assert_response :success
        # Grades default sort is by level ascending
        assert_select "tbody tr:nth-child(1)", text: /Kindergarten/
        assert_select "tbody tr:nth-child(2)", text: /First Grade/
        assert_select "tbody tr:nth-child(3)", text: /Second Grade/
      end

      test "sorts by specified column ascending" do
        get admin_v2_grades_path, params: { sort: "name", direction: "asc" }

        assert_response :success
        # Name ascending: First, Kindergarten, Second
        assert_select "tbody tr:nth-child(1)", text: /First Grade/
        assert_select "tbody tr:nth-child(2)", text: /Kindergarten/
        assert_select "tbody tr:nth-child(3)", text: /Second Grade/
      end

      test "sorts by specified column descending" do
        get admin_v2_grades_path, params: { sort: "name", direction: "desc" }

        assert_response :success
        # Name descending: Second, Kindergarten, First
        assert_select "tbody tr:nth-child(1)", text: /Second Grade/
        assert_select "tbody tr:nth-child(2)", text: /Kindergarten/
        assert_select "tbody tr:nth-child(3)", text: /First Grade/
      end

      test "defaults to ascending when direction not specified" do
        get admin_v2_grades_path, params: { sort: "level" }

        assert_response :success
        # Level ascending (default direction): 0, 1, 2
        assert_select "tbody tr:nth-child(1)", text: /Kindergarten/
        assert_select "tbody tr:nth-child(2)", text: /First Grade/
        assert_select "tbody tr:nth-child(3)", text: /Second Grade/
      end
    end
  end
end
