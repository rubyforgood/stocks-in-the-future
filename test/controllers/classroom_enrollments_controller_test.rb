# frozen_string_literal: true

require "test_helper"

class ClassroomEnrollmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @classroom = create(:classroom)
    @student = create(:student, classroom: @classroom)
    @teacher = create(:teacher)
    @teacher.classrooms << @classroom
  end

  # create

  test "create enrolls student in classroom" do
    other_classroom = create(:classroom)
    sign_in(@teacher)

    assert_difference("ClassroomEnrollment.count") do
      post classroom_classroom_enrollments_path(other_classroom),
           params: { classroom_enrollment: { student_id: @student.id, primary: "false" } }
    end

    assert_redirected_to classroom_path(other_classroom)
    assert_match @student.username, flash[:notice]
    assert_match other_classroom.name, flash[:notice]
  end

  test "create enrolls student as primary" do
    other_classroom = create(:classroom)
    sign_in(@teacher)

    post classroom_classroom_enrollments_path(other_classroom),
         params: { classroom_enrollment: { student_id: @student.id, primary: "true" } }

    enrollment = ClassroomEnrollment.last
    assert enrollment.primary?
    assert_redirected_to classroom_path(other_classroom)
  end

  # destroy

  test "destroy removes enrollment" do
    enrollment = create(:classroom_enrollment, classroom: @classroom, student: @student)
    sign_in(@teacher)

    assert_difference("ClassroomEnrollment.count", -1) do
      delete classroom_classroom_enrollment_path(@classroom, enrollment)
    end

    assert_redirected_to classroom_path(@classroom)
    assert_match @student.username, flash[:notice]
    assert_match @classroom.name, flash[:notice]
  end

  # unenroll

  test "unenroll sets unenrolled_at on enrollment" do
    enrollment = create(:classroom_enrollment, classroom: @classroom, student: @student)
    sign_in(@teacher)

    patch unenroll_classroom_classroom_enrollment_path(@classroom, enrollment)

    assert enrollment.reload.historical?
    assert_redirected_to classroom_path(@classroom)
    assert_match @student.username, flash[:notice]
  end

  # authorization

  test "student cannot create enrollment" do
    other_classroom = create(:classroom)
    sign_in(@student)

    post classroom_classroom_enrollments_path(other_classroom),
         params: { classroom_enrollment: { student_id: @student.id, primary: "false" } }

    assert_equal "You do not have access to this page.", flash[:alert]
  end

  test "unauthenticated user is redirected to sign in" do
    post classroom_classroom_enrollments_path(@classroom),
         params: { classroom_enrollment: { student_id: @student.id, primary: "false" } }

    assert_redirected_to new_user_session_path
  end
end
