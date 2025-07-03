# frozen_string_literal: true

require "test_helper"

class ClassroomTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:classroom).validate!
  end

  test "destroying classroom nullifies user classroom_id instead of destroying users" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    teacher = create(:teacher, classroom: classroom)
    admin = create(:admin, classroom: classroom)

    user_ids = [student.id, teacher.id, admin.id]

    classroom.destroy!

    user_ids.each do |user_id|
      assert User.exists?(user_id), "User #{user_id} should still exist after classroom destruction"
    end

    [student, teacher, admin].each do |user|
      user.reload
      assert_nil user.classroom_id, "User #{user.id} classroom_id should be null after classroom destruction"
    end
  end
end
