# frozen_string_literal: true

require "test_helper"

class ClassroomTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:classroom).validate!
  end

  # SchoolYearFields. No form asks for a SchoolYear - both halves offer a School and a Year and the pair
  # is found-or-created - so the validation is on the two fields a reader can see.
  test "a blank form reports the two fields it has, not the association they combine into" do
    classroom = Classroom.new(name: "5B")

    assert_not classroom.valid?
    assert_includes classroom.errors[:school_id], "can't be blank"
    assert_includes classroom.errors[:year_id], "can't be blank"
    # "School year must exist" named a field neither form has, so nothing was marked.
    assert_empty classroom.errors[:school_year]
  end

  test "a school year assigned directly satisfies it, even unsaved" do
    # `build` hands over an unsaved SchoolYear whose own school_id is still nil, which is why this checks
    # the association rather than the ids.
    assert_predicate build(:classroom), :valid?
  end

  test "the two fields are found or created into a school year" do
    school = create(:school)
    year = create(:year)
    classroom = create(
      :classroom, school_year: nil, school_id: school.id, year_id: year.id,
                  grades: [create(:grade)]
    )

    assert_equal school, classroom.school_year.school
    assert_equal year, classroom.school_year.year
  end

  test "an existing school year is reused rather than duplicated" do
    existing = create(:school_year)
    classroom = create(
      :classroom, school_year: nil, school_id: existing.school_id,
                  year_id: existing.year_id, grades: [create(:grade)]
    )

    assert_equal existing, classroom.school_year
  end

  test "a failed save leaves no orphan school year behind" do
    school = create(:school)
    year = create(:year)

    assert_no_difference("SchoolYear.count") do
      Classroom.new(name: "", school_id: school.id, year_id: year.id).save
    end
  end

  test "clearing a select clears the field rather than silently keeping the old value" do
    classroom = create(:classroom)
    classroom.assign_attributes(school_id: "", year_id: "")

    assert_not classroom.valid?
    assert_includes classroom.errors[:school_id], "can't be blank"
  end

  test "the readers fall back to the association, so an edit form repopulates itself" do
    classroom = create(:classroom)

    assert_equal classroom.school_year.school_id, classroom.school_id
    assert_equal classroom.school_year.year_id, classroom.year_id
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

  test "creates gradebooks for all quarters when classroom is created" do
    school_year = create(:school_year)

    assert_difference("GradeBook.count", 4) do
      classroom = create(:classroom, school_year: school_year)

      school_year.quarters.each do |quarter|
        assert GradeBook.exists?(classroom: classroom, quarter: quarter)
      end
    end
  end

  # Tests for sorting scopes
  test "order_by_name sorts by name ascending" do
    create(:classroom, name: "Zebra")
    create(:classroom, name: "Alpha")
    create(:classroom, name: "Middle")

    classrooms = Classroom.order_by_name(:asc)
    assert_equal %w[Alpha Middle Zebra], classrooms.pluck(:name)
  end

  test "order_by_name sorts by name descending" do
    create(:classroom, name: "Zebra")
    create(:classroom, name: "Alpha")
    create(:classroom, name: "Middle")

    classrooms = Classroom.order_by_name(:desc)
    assert_equal %w[Zebra Middle Alpha], classrooms.pluck(:name)
  end

  test "order_by_student_count sorts by student count" do
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)
    create(:student, classroom: classroom1)
    create(:student, classroom: classroom1)
    create(:student, classroom: classroom2)

    classrooms = Classroom.order_by_student_count(:desc)
    assert_equal classroom1.id, classrooms.first.id
    assert_equal classroom2.id, classrooms.last.id
  end

  test "apply_sorting defaults to name ascending" do
    create(:classroom, name: "Zebra")
    create(:classroom, name: "Alpha")

    classrooms = Classroom.apply_sorting(nil, nil, nil)
    assert_equal %w[Alpha Zebra], classrooms.pluck(:name)
  end

  test "apply_sorting with sort_column applies correct scope" do
    classroom1 = create(:classroom, name: "Zebra")
    classroom2 = create(:classroom, name: "Alpha")
    create(:student, classroom: classroom1)
    create(:student, classroom: classroom2)
    create(:student, classroom: classroom1)

    classrooms = Classroom.apply_sorting(nil, "student_count", :desc)
    assert_equal classroom1.id, classrooms.first.id
  end
end
