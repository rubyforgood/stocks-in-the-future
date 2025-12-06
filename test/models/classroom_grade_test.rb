# frozen_string_literal: true

require "test_helper"

class ClassroomGradeTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:classroom_grade).validate!
  end

  test "belongs to classroom" do
    classroom = create(:classroom)
    cg = create(:classroom_grade, classroom: classroom)

    assert_equal classroom, cg.classroom
  end

  test "belongs to grade" do
    grade = create(:grade)
    cg = create(:classroom_grade, grade: grade)

    assert_equal grade, cg.grade
  end

  test "validates uniqueness of grade scoped to classroom" do
    classroom = create(:classroom)
    grade = create(:grade)
    create(:classroom_grade, classroom: classroom, grade: grade)

    duplicate = build(:classroom_grade, classroom: classroom, grade: grade)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:grade_id], "has already been taken"
  end

  test "destroying classroom destroys classroom_grade" do
    classroom = create(:classroom)
    create(:classroom_grade, classroom: classroom)

    assert_difference "ClassroomGrade.count", -1 do
      classroom.destroy
    end
  end

  test "destroying grade destroys classroom_grade" do
    grade = create(:grade)
    create(:classroom_grade, grade: grade)

    assert_difference "ClassroomGrade.count", -1 do
      grade.destroy
    end
  end
end
