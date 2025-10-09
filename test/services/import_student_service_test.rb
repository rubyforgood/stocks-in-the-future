# frozen_string_literal: true

require "test_helper"

class ImportStudentServiceTest < ActiveSupport::TestCase
  def setup
    @classroom = create(:classroom)
  end

  test "call creates student successfully" do
    assert_difference("Student.count", 1) do
      result = ImportStudentService.call(
        username: "student001",
        classroom_id: @classroom.id
      )

      assert result.success?
      assert_equal :created, result.action
      assert_equal "student001", result.student.username
      assert_equal @classroom, result.student.classroom
      assert_nil result.error_message
    end
  end

  test "call skips duplicate username" do
    create(:student, username: "existing_user", classroom: @classroom)

    assert_no_difference("Student.count") do
      result = ImportStudentService.call(
        username: "existing_user",
        classroom_id: @classroom.id
      )

      assert result.success?
      assert_equal :skipped, result.action
      assert_nil result.student
      assert_equal "Student with username 'existing_user' already exists", result.error_message
    end
  end

  test "call handles invalid classroom_id" do
    assert_no_difference("Student.count") do
      result = ImportStudentService.call(
        username: "student001",
        classroom_id: "999"
      )

      assert_not result.success?
      assert_equal :failed, result.action
      assert_not_nil result.student
      assert_not result.student.persisted?
      assert_match(/Classroom can't be blank/, result.error_message)
    end
  end

  test "call handles blank username" do
    assert_no_difference("Student.count") do
      result = ImportStudentService.call(
        username: "",
        classroom_id: @classroom.id
      )

      assert result.success?
      assert_equal :skipped, result.action
      assert_nil result.student
      assert_equal "Username is required", result.error_message
    end
  end

  test "call handles nil username" do
    assert_no_difference("Student.count") do
      result = ImportStudentService.call(
        username: nil,
        classroom_id: @classroom.id
      )

      assert result.success?
      assert_equal :skipped, result.action
      assert_nil result.student
      assert_equal "Username is required", result.error_message
    end
  end

  test "call strips whitespace from parameters" do
    assert_difference("Student.count", 1) do
      result = ImportStudentService.call(
        username: "  student001  ",
        classroom_id: "  #{@classroom.id}  "
      )

      assert result.success?
      assert_equal :created, result.action
      assert_equal "student001", result.student.username
    end
  end

  test "call generates password for created student" do
    result = ImportStudentService.call(
      username: "student001",
      classroom_id: @classroom.id
    )

    assert result.success?
    assert_not_nil result.student.password
    assert result.student.password.length.positive?
  end
end
