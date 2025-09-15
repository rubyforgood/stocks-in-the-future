# frozen_string_literal: true

require "test_helper"

class TeacherClassroomTest < ActiveSupport::TestCase
  test "valid teacher_classroom" do
    teacher = create(:teacher)
    classroom = create(:classroom)
    teacher_classroom = TeacherClassroom.new(teacher: teacher, classroom: classroom)

    assert teacher_classroom.valid?
  end

  test "requires teacher" do
    classroom = create(:classroom)
    teacher_classroom = TeacherClassroom.new(classroom: classroom)

    assert_not teacher_classroom.valid?
    assert_includes teacher_classroom.errors[:teacher], "must exist"
  end

  test "requires classroom" do
    teacher = create(:teacher)
    teacher_classroom = TeacherClassroom.new(teacher: teacher)

    assert_not teacher_classroom.valid?
    assert_includes teacher_classroom.errors[:classroom], "must exist"
  end

  test "validates uniqueness of teacher_id scoped to classroom_id" do
    teacher = create(:teacher)
    classroom = create(:classroom)

    TeacherClassroom.create!(teacher: teacher, classroom: classroom)

    duplicate = TeacherClassroom.new(teacher: teacher, classroom: classroom)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:teacher_id], "has already been taken"
  end

  test "allows same teacher in different classrooms" do
    teacher = create(:teacher)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    assert TeacherClassroom.create(teacher: teacher, classroom: classroom1)
    assert TeacherClassroom.create(teacher: teacher, classroom: classroom2)
  end

  test "allows different teachers in same classroom" do
    teacher1 = create(:teacher)
    teacher2 = create(:teacher)
    classroom = create(:classroom)

    assert TeacherClassroom.create(teacher: teacher1, classroom: classroom)
    assert TeacherClassroom.create(teacher: teacher2, classroom: classroom)
  end
end
