# frozen_string_literal: true

require "test_helper"

class GradeTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:grade).validate!
  end

  test "has many classroom_grades" do
    grade = create(:grade)
    cg1 = create(:classroom_grade, grade: grade)
    cg2 = create(:classroom_grade, grade: grade)

    assert_equal 2, grade.classroom_grades.count
    assert_includes grade.classroom_grades, cg1
    assert_includes grade.classroom_grades, cg2
  end

  test "has many classrooms through classroom_grades" do
    grade = create(:grade)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)
    create(:classroom_grade, grade: grade, classroom: classroom1)
    create(:classroom_grade, grade: grade, classroom: classroom2)

    assert_equal 2, grade.classrooms.count
    assert_includes grade.classrooms, classroom1
    assert_includes grade.classrooms, classroom2
  end

  test "dependent_destroy destroys classroom_grades" do
    grade = create(:grade)
    create(:classroom_grade, grade: grade)

    assert_difference "ClassroomGrade.count", -1 do
      grade.destroy
    end
  end
end
