# frozen_string_literal: true

require "test_helper"

class ClassroomTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:classroom).validate!
  end

  test "name is required" do
    classroom = build(:classroom, name: "")
    assert_not classroom.valid?
    assert_includes classroom.errors[:name], "can't be blank"
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

  test "has many students through classrooms association" do
    classroom = create(:classroom)
    student1 = create(:student, classroom: classroom)
    student2 = create(:student, classroom: classroom)

    assert_includes classroom.students, student1
    assert_includes classroom.students, student2
    assert_equal 2, classroom.students.count
  end

  test "has many teachers through teacher_classrooms association" do
    classroom = create(:classroom)
    teacher1 = create(:teacher, classrooms: [classroom])
    teacher2 = create(:teacher, classrooms: [classroom])

    assert_includes classroom.teachers, teacher1
    assert_includes classroom.teachers, teacher2
    assert_equal 2, classroom.teachers.count
  end

  test "students association only includes Student type users" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    teacher = create(:teacher, classroom: classroom)
    admin = create(:admin, classroom: classroom)

    assert_includes classroom.students, student
    assert_not_includes classroom.students, teacher
    assert_not_includes classroom.students, admin
  end

  test "teachers association only includes Teacher type users" do
    classroom = create(:classroom)
    student   = create(:student)
    admin     = create(:admin)

    assert_raises(ActiveRecord::AssociationTypeMismatch) { classroom.teachers << student }
    assert_raises(ActiveRecord::AssociationTypeMismatch) { classroom.teachers << admin }
  end

  test "students association excludes discarded students" do
    classroom = create(:classroom)
    kept_student = create(:student, classroom: classroom)
    discarded_student = create(:student, classroom: classroom)
    discarded_student.discard

    assert_includes classroom.students, kept_student
    assert_not_includes classroom.students, discarded_student
    assert_equal [kept_student.id], classroom.students.pluck(:id)
  end
end
