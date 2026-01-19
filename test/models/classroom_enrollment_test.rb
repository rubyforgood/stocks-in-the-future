# frozen_string_literal: true

require "test_helper"

class ClassroomEnrollmentTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:classroom_enrollment).valid?
  end

  test "belongs to student" do
    enrollment = build(:classroom_enrollment)
    assert enrollment.respond_to?(:student)
  end

  test "belongs to classroom" do
    enrollment = build(:classroom_enrollment)
    assert enrollment.respond_to?(:classroom)
  end

  test "requires student_id" do
    enrollment = build(:classroom_enrollment, student: nil)
    assert_not enrollment.valid?
    assert_includes enrollment.errors[:student], "must exist"
  end

  test "requires classroom_id" do
    enrollment = build(:classroom_enrollment, classroom: nil)
    assert_not enrollment.valid?
    assert_includes enrollment.errors[:classroom], "must exist"
  end

  test "requires enrolled_at" do
    enrollment = build(:classroom_enrollment, enrolled_at: nil)
    assert_not enrollment.valid?
    assert_includes enrollment.errors[:enrolled_at], "can't be blank"
  end

  test "unenrolled_at must be after enrolled_at" do
    enrollment = build(:classroom_enrollment,
                       enrolled_at: 1.day.ago,
                       unenrolled_at: 2.days.ago)
    assert_not enrollment.valid?
    assert_includes enrollment.errors[:unenrolled_at], "must be after enrolled_at"
  end

  test "unenrolled_at can be equal to enrolled_at" do
    time = Time.current
    enrollment = build(:classroom_enrollment,
                       enrolled_at: time,
                       unenrolled_at: time)
    assert enrollment.valid?
  end

  test "student can only have one primary enrollment" do
    student = create(:student, :without_enrollment)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    create(:classroom_enrollment, student: student, classroom: classroom1, primary: true)
    enrollment2 = build(:classroom_enrollment, student: student, classroom: classroom2, primary: true)

    assert_not enrollment2.valid?
    assert_includes enrollment2.errors[:primary], "student can only have one primary enrollment"
  end

  test "current scope returns enrollments with nil unenrolled_at" do
    student = create(:student, :without_enrollment)
    current = create(:classroom_enrollment, student: student, unenrolled_at: nil)
    historical = create(:classroom_enrollment, student: student, enrolled_at: 2.days.ago, unenrolled_at: 1.day.ago)

    assert_includes ClassroomEnrollment.current, current
    assert_not_includes ClassroomEnrollment.current, historical
  end

  test "historical scope returns enrollments with unenrolled_at set" do
    student = create(:student, :without_enrollment)
    current = create(:classroom_enrollment, student: student, unenrolled_at: nil)
    historical = create(:classroom_enrollment, student: student, enrolled_at: 2.days.ago, unenrolled_at: 1.day.ago)

    assert_includes ClassroomEnrollment.historical, historical
    assert_not_includes ClassroomEnrollment.historical, current
  end

  test "primary_enrollment scope returns only primary enrollments" do
    student1 = create(:student, :without_enrollment)
    student2 = create(:student, :without_enrollment)
    primary = create(:classroom_enrollment, student: student1, primary: true)
    non_primary = create(:classroom_enrollment, student: student2, primary: false)

    assert_includes ClassroomEnrollment.primary_enrollment, primary
    assert_not_includes ClassroomEnrollment.primary_enrollment, non_primary
  end

  test "make_primary! marks enrollment as primary" do
    student = create(:student)
    enrollment = create(:classroom_enrollment, student: student, primary: false)

    enrollment.make_primary!

    assert enrollment.reload.primary
  end

  test "make_primary! demotes other primary enrollments for same student" do
    student = create(:student, :without_enrollment)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)
    old_primary = create(:classroom_enrollment, student: student, classroom: classroom1, primary: true)
    new_enrollment = create(:classroom_enrollment, student: student, classroom: classroom2, primary: false)

    new_enrollment.make_primary!

    assert_not old_primary.reload.primary
    assert new_enrollment.reload.primary
  end

  test "make_primary! returns self" do
    enrollment = create(:classroom_enrollment)
    result = enrollment.make_primary!
    assert_equal enrollment, result
  end

  test "unenroll! sets unenrolled_at to current time by default" do
    student = create(:student, :without_enrollment)
    enrollment = create(:classroom_enrollment, student: student, enrolled_at: 1.hour.ago, unenrolled_at: nil,
                                               primary: true)

    freeze_time do
      enrollment.unenroll!
      assert_in_delta Time.current, enrollment.reload.unenrolled_at, 1.second
    end
  end

  test "unenroll! accepts custom unenrollment time" do
    student = create(:student, :without_enrollment)
    enrollment = create(:classroom_enrollment, student: student, enrolled_at: 2.weeks.ago, unenrolled_at: nil)
    custom_time = 1.week.ago

    enrollment.unenroll!(at: custom_time)

    assert_in_delta custom_time, enrollment.reload.unenrolled_at, 1.second
  end

  test "unenroll! sets primary to false" do
    student = create(:student, :without_enrollment)
    enrollment = create(:classroom_enrollment, student: student, primary: true)

    enrollment.unenroll!

    assert_not enrollment.reload.primary
  end

  test "unenroll! returns self" do
    enrollment = create(:classroom_enrollment)
    result = enrollment.unenroll!
    assert_equal enrollment, result
  end

  test "current? returns true when unenrolled_at is nil" do
    enrollment = build(:classroom_enrollment, unenrolled_at: nil)
    assert enrollment.current?
  end

  test "current? returns false when unenrolled_at is set" do
    enrollment = build(:classroom_enrollment, unenrolled_at: 1.day.ago)
    assert_not enrollment.current?
  end

  test "historical? returns false when unenrolled_at is nil" do
    enrollment = build(:classroom_enrollment, unenrolled_at: nil)
    assert_not enrollment.historical?
  end

  test "historical? returns true when unenrolled_at is set" do
    enrollment = build(:classroom_enrollment, unenrolled_at: 1.day.ago)
    assert enrollment.historical?
  end
end
