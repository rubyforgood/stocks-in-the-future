# frozen_string_literal: true

require "test_helper"

class ClassroomTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:classroom).validate!
  end

  test "destroying classroom nullifies user classroom_id instead of destroying users" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    teacher = create(:teacher)
    teacher.classrooms << classroom
    admin = create(:admin, classroom: classroom)

    user_ids = [student.id, teacher.id, admin.id]

    classroom.destroy!

    user_ids.each do |user_id|
      assert User.exists?(user_id), "User #{user_id} should still exist after classroom destruction"
    end

    # Students and admins should have their classroom_id nullified
    [student, admin].each do |user|
      user.reload
      assert_nil user.classroom_id, "User #{user.id} classroom_id should be null after classroom destruction"
    end

    # Teachers should still exist but have no classrooms
    teacher.reload
    assert_equal 0, teacher.classrooms.count, "Teacher should have no classrooms after classroom destruction"
  end

  test "teachers can belong to multiple classrooms" do
    teacher = create(:teacher)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    teacher.classrooms << classroom1
    teacher.classrooms << classroom2

    assert_equal 2, teacher.classrooms.count
    assert_includes teacher.classrooms, classroom1
    assert_includes teacher.classrooms, classroom2
  end
end
