# frozen_string_literal: true

require "test_helper"

class StudentTest < ActiveSupport::TestCase
  test "inherits from User" do
    student = create(:student)
    assert_kind_of User, student
    assert_equal "Student", student.type
  end

  test "belongs to classroom" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    assert_equal classroom, student.classroom
  end

  test "has portfolio association" do
    student = create(:student)
    portfolio = create(:portfolio, user: student)
    assert_equal portfolio, student.portfolio
  end

  test "email can be blank for students" do
    student = build(:student, email: "")
    assert student.valid?
  end

  test "password generation works" do
    student = create(:student)
    assert_not_nil student.encrypted_password
  end

  test "destroy raises and does not delete the row" do
    student = create(:student)
    assert_raises(RuntimeError) { student.destroy }
    assert student.reload.persisted?
    assert_not student.discarded?
  end

  test "has many classroom_enrollments" do
    student = create(:student)
    assert student.respond_to?(:classroom_enrollments)
  end

  test "has many classrooms through classroom_enrollments" do
    student = create(:student)
    assert student.respond_to?(:classrooms)
  end

  test "current_enrollments returns only enrollments with nil unenrolled_at" do
    student = create(:student, :without_enrollment)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    current = create(
      :classroom_enrollment,
      student: student,
      classroom: classroom1,
      unenrolled_at: nil
    )
    historical = create(
      :classroom_enrollment,
      student: student,
      classroom: classroom2,
      enrolled_at: 2.days.ago,
      unenrolled_at: 1.day.ago
    )

    assert_includes student.current_enrollments, current
    assert_not_includes student.current_enrollments, historical
  end

  test "current_classrooms returns classrooms with active enrollments" do
    student = create(:student, :without_enrollment)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)
    classroom3 = create(:classroom)

    create(
      :classroom_enrollment,
      student: student,
      classroom: classroom1,
      unenrolled_at: nil
    )
    create(
      :classroom_enrollment,
      student: student,
      classroom: classroom2,
      unenrolled_at: nil
    )
    create(
      :classroom_enrollment,
      student: student,
      classroom: classroom3,
      enrolled_at: 2.days.ago,
      unenrolled_at: 1.day.ago
    )

    assert_includes student.current_classrooms, classroom1
    assert_includes student.current_classrooms, classroom2
    assert_not_includes student.current_classrooms, classroom3
  end

  test "primary_enrollment returns the primary enrollment" do
    student = create(:student, :without_enrollment)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    primary = create(
      :classroom_enrollment,
      student: student,
      classroom: classroom1,
      primary: true
    )
    create(
      :classroom_enrollment,
      student: student,
      classroom: classroom2,
      primary: false
    )

    assert_equal primary, student.primary_enrollment
  end

  test "primary_classroom returns primary enrollment classroom" do
    student = create(:student, :without_enrollment)
    classroom = create(:classroom)

    create(
      :classroom_enrollment,
      student: student,
      classroom: classroom,
      primary: true
    )

    assert_equal classroom, student.primary_classroom
  end

  test "primary_classroom falls back to classroom_id when no primary enrollment" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)

    assert_equal classroom, student.primary_classroom
  end

  test "enroll_in! creates a new enrollment" do
    student = create(:student)
    classroom = create(:classroom)

    assert_difference -> { student.classroom_enrollments.count }, 1 do
      student.enroll_in!(classroom)
    end
  end

  test "enroll_in! sets enrolled_at to current time by default" do
    student = create(:student)
    classroom = create(:classroom)

    freeze_time do
      enrollment = student.enroll_in!(classroom)
      assert_in_delta Time.current, enrollment.enrolled_at, 1.second
    end
  end

  test "enroll_in! accepts custom enrolled_at time" do
    student = create(:student)
    classroom = create(:classroom)
    custom_time = 1.week.ago

    enrollment = student.enroll_in!(classroom, enrolled_at: custom_time)

    assert_in_delta custom_time, enrollment.enrolled_at, 1.second
  end

  test "enroll_in! sets primary flag when requested" do
    student = create(:student, :without_enrollment)
    classroom = create(:classroom)

    enrollment = student.enroll_in!(classroom, primary: true)

    assert enrollment.primary
  end

  test "enroll_in! demotes other primary enrollments when creating new primary" do
    student = create(:student, :without_enrollment)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    old_primary = create(
      :classroom_enrollment,
      student: student,
      classroom: classroom1,
      primary: true
    )

    student.enroll_in!(classroom2, primary: true)

    assert_not old_primary.reload.primary
  end

  test "enroll_in! returns the enrollment" do
    student = create(:student)
    classroom = create(:classroom)

    enrollment = student.enroll_in!(classroom)

    assert_kind_of ClassroomEnrollment, enrollment
    assert enrollment.persisted?
  end

  test "unenroll_from! sets unenrolled_at on enrollment" do
    student = create(:student)
    classroom = create(:classroom)
    enrollment = create(
      :classroom_enrollment,
      student: student,
      classroom: classroom
    )

    student.unenroll_from!(classroom)

    assert_not_nil enrollment.reload.unenrolled_at
  end

  test "unenroll_from! sets unenrolled_at to current time by default" do
    student = create(:student, :without_enrollment)
    classroom = create(:classroom)
    enrollment = create(
      :classroom_enrollment,
      student: student,
      classroom: classroom,
      enrolled_at: 1.hour.ago
    )

    freeze_time do
      student.unenroll_from!(classroom)
      assert_in_delta Time.current, enrollment.reload.unenrolled_at, 1.second
    end
  end

  test "unenroll_from! accepts custom unenrollment time" do
    student = create(:student, :without_enrollment)
    classroom = create(:classroom)
    enrollment = create(
      :classroom_enrollment,
      student: student,
      classroom: classroom,
      enrolled_at: 2.weeks.ago
    )
    custom_time = 1.week.ago

    student.unenroll_from!(classroom, unenrolled_at: custom_time)

    assert_in_delta custom_time, enrollment.reload.unenrolled_at, 1.second
  end

  test "unenroll_from! handles multiple enrollments for same classroom" do
    student = create(:student)
    classroom = create(:classroom)
    enrollment1 = create(
      :classroom_enrollment,
      student: student,
      classroom: classroom,
      enrolled_at: 1.month.ago
    )
    enrollment2 = create(
      :classroom_enrollment,
      student: student,
      classroom: classroom,
      enrolled_at: 2.weeks.ago
    )

    student.unenroll_from!(classroom)

    assert_not_nil enrollment1.reload.unenrolled_at
    assert_not_nil enrollment2.reload.unenrolled_at
  end

  test "automatically creates enrollment when student is created with classroom_id" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)

    assert_equal 1, student.classroom_enrollments.count
    assert_equal classroom, student.classroom_enrollments.first.classroom
    assert student.classroom_enrollments.first.primary
  end

  test "does not create enrollment when student is created without classroom_id" do
    student = Student.create!(username: "test_#{rand(10_000)}", password: "Test1234")

    assert_equal 0, student.classroom_enrollments.count
  end
end
