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
        classroom_id: @classroom.id,
        name: "Test Student"
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
        classroom_id: @classroom.id,
        name: "Test Student"
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
        classroom_id: "999",
        name: "Test Student"
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
        classroom_id: @classroom.id,
        name: "Test Student"
      )

      assert_not result.success?
      assert_predicate result, :failed?
      assert_nil result.student
      assert_equal "Username is required", result.error_message
    end
  end

  test "call handles nil username" do
    assert_no_difference("Student.count") do
      result = ImportStudentService.call(
        username: nil,
        classroom_id: @classroom.id,
        name: "Test Student"
      )

      assert_not result.success?
      assert_predicate result, :failed?
      assert_nil result.student
      assert_equal "Username is required", result.error_message
    end
  end

  test "call strips whitespace from parameters" do
    assert_difference("Student.count", 1) do
      result = ImportStudentService.call(
        username: "  student001  ",
        classroom_id: "  #{@classroom.id}  ",
        name: "Test Student"
      )

      assert result.success?
      assert_equal :created, result.action
      assert_equal "student001", result.student.username
    end
  end

  test "call generates password for created student" do
    result = ImportStudentService.call(
      username: "student001",
      classroom_id: @classroom.id,
      name: "Test Student"
    )

    assert result.success?
    assert_not_nil result.student.password
    assert result.student.password.length.positive?
  end

  # A name is required on import as well as on the forms, so the rule is the same however a student
  # arrives. It was optional for one commit, on the argument that an import should not drop a row it could
  # otherwise create - but a bulk-imported class is exactly where a roster of lowercased usernames is
  # least navigable, and it is the path that creates twenty-five of them at once.
  # A failure rather than a skip, deliberately: the importer reports skips as "Skipped N existing
  # usernames", which would mislabel a row that simply has no name, while failures are listed per row as
  # "Row N: <message>" - what someone fixing a spreadsheet actually needs.
  test "call refuses a row with no name" do
    assert_no_difference("Student.count") do
      result = ImportStudentService.call(
        username: "student001",
        classroom_id: @classroom.id,
        name: nil
      )

      assert_not result.success?
      assert_predicate result, :failed?
      assert_equal "Name is required", result.error_message
    end
  end

  test "call refuses a row whose name is only whitespace" do
    assert_no_difference("Student.count") do
      result = ImportStudentService.call(
        username: "student001",
        classroom_id: @classroom.id,
        name: "   "
      )

      assert_equal "Name is required", result.error_message
      assert_predicate result, :failed?
    end
  end

  test "call keeps the name it is given" do
    ImportStudentService.call(
      username: "student001",
      classroom_id: @classroom.id,
      name: "  Ada Lovelace  "
    )

    assert_equal "Ada Lovelace", Student.find_by(username: "student001").name
  end
end
