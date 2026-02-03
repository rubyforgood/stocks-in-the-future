# frozen_string_literal: true

require "test_helper"

module AdminV2
  module Teachers
    class DeactivationsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:admin, admin: true)
        sign_in(@admin)

        @classroom1 = create(:classroom, name: "Math 101")
        @teacher1 = create(:teacher, username: "teacher1", email: "teacher1@example.com")
        @teacher1.classrooms << @classroom1
      end

      test "should deactivate teacher" do
        assert_no_difference("Teacher.count") do
          post admin_v2_teacher_deactivation_path(@teacher1)
        end

        assert_redirected_to admin_v2_teachers_path
        assert_equal "Teacher teacher1 deactivated successfully.", flash[:notice]
        assert @teacher1.reload.discarded?
      end

      test "deactivate should soft delete teacher" do
        post admin_v2_teacher_deactivation_path(@teacher1)

        # Teacher should still exist in database
        assert_not_nil Teacher.with_discarded.find_by(id: @teacher1.id)
        # But should not appear in kept scope
        assert_nil Teacher.kept.find_by(id: @teacher1.id)
        # Should have discarded_at timestamp
        assert_not_nil @teacher1.reload.discarded_at
      end
    end
  end
end
