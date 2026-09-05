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

  test "can destroy a grade with no classrooms" do
    grade = create(:grade)

    assert_difference "Grade.count", -1 do
      grade.destroy
    end
  end

  test "cannot destroy a grade that is used by classrooms" do
    grade = create(:grade)
    create(:classroom_grade, grade: grade)

    assert_not grade.destroy
    assert grade.errors.any?
    assert_includes grade.errors[:base], "Cannot delete record because dependent classroom grades exist"
  end

  test "name must be present" do
    grade = build(:grade, name: nil)
    assert_not grade.valid?
    assert_includes grade.errors[:name], "can't be blank"
  end

  test "level must be present" do
    grade = build(:grade, level: nil)
    assert_not grade.valid?
    assert_includes grade.errors[:level], "can't be blank"
  end

  test "name is unique and case-insensitively" do
    create(:grade, name: "5th Grade", level: 6)

    duplicate = build(:grade, name: "5TH grade", level: 6)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "level is unique" do
    create(:grade, name: "5th Grade", level: 6)

    duplicate = build(:grade, name: "5th Grade", level: 6)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:level], "has already been taken"
  end

  # Levels a school actually uses, which tests hard code when the value matters.
  REAL_GRADE_LEVELS = (1..12)

  test "the factory generates levels clear of the ones tests hard code" do
    generated = Array.new(20) { create(:grade).level }
    overlapping = generated.select { |level| REAL_GRADE_LEVELS.cover?(level) }

    assert_empty overlapping,
                 "generated levels must stay out of #{REAL_GRADE_LEVELS}, or a test that " \
                 "hard codes a real level fails once its worker's sequence reaches it"
  end

  test "a hard coded real level is still available after many generated grades" do
    Array.new(20) { create(:grade) }

    REAL_GRADE_LEVELS.each do |level|
      assert create(:grade, level: level, name: "Real grade #{level}").persisted?
    end
  end
end
