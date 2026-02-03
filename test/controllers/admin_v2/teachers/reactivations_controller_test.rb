# frozen_string_literal: true

require "test_helper"

module AdminV2
  module Teachers
    class ReactivationsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:admin, admin: true)
        sign_in(@admin)

        @classroom1 = create(:classroom, name: "Math 101")
        @teacher1 = create(:teacher, username: "teacher1", email: "teacher1@example.com")
        @teacher1.classrooms << @classroom1
      end

      test "should reactivate deactivated teacher" do
        @teacher1.discard

        assert @teacher1.discarded?

        post admin_v2_teacher_reactivation_path(@teacher1)

        assert_redirected_to admin_v2_teachers_path
        assert_equal "Teacher teacher1 reactivated successfully.", flash[:notice]
        assert_not @teacher1.reload.discarded?
      end

      test "reactivate should restore teacher to active status" do
        @teacher1.discard
        assert_not_nil @teacher1.reload.discarded_at

        post admin_v2_teacher_reactivation_path(@teacher1)

        # Should clear discarded_at timestamp
        assert_nil @teacher1.reload.discarded_at
        # Should appear in kept scope
        assert_not_nil Teacher.kept.find_by(id: @teacher1.id)
      end
    end
  end
end
