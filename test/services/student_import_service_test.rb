# frozen_string_literal: true

require "test_helper"

class StudentImportServiceTest < ActiveSupport::TestCase
  def setup
    @service = StudentImportService.new
    @classroom1 = create(:classroom)
    @classroom2 = create(:classroom)
    @csv_header = "classroom_id,username"
  end

  test "import_from_csv creates students successfully" do
    csv_content = [
      @csv_header,
      "#{@classroom1.id},student001",
      "#{@classroom2.id},student002"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference("Student.count", 2) do
        service = @service.import_from_csv(csv_file.path)

        assert service.success?
        assert_equal 2, service.created_count
        assert_equal %w[student001 student002], service.created_students
        assert_equal 0, service.skipped_count
        assert service.errors.empty?
      end
    end
  end

  test "import_from_csv skips duplicate usernames" do
    create(:student, username: "existing_user", classroom: @classroom1)

    csv_content = "classroom_id,username\n#{@classroom1.id},existing_user\n#{@classroom1.id},new_user"

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference("Student.count", 1) do
        service = @service.import_from_csv(csv_file.path)

        assert service.success?
        assert_equal 1, service.created_count
        assert_equal %w[new_user], service.created_students
        assert_equal 1, service.skipped_count
        assert_equal %w[existing_user], service.skipped_students
      end
    end
  end

  test "import_from_csv handles validation errors" do
    csv_content = "classroom_id,username\n999,invalid_classroom\n#{@classroom1.id},"

    with_temp_csv_file(csv_content) do |csv_file|
      assert_no_difference("Student.count") do
        service = @service.import_from_csv(csv_file.path)

        assert service.success?, "Service completes successfully but records validation errors"
        assert_equal 0, service.created_count
        assert_equal 1, service.errors.count, "Should have 1 error for invalid classroom_id (empty username is skipped)"
        assert(service.errors.full_messages.any? { |error| error.include?("Classroom ID '999' not found") })
      end
    end
  end

  test "import_from_csv handles malformed CSV" do
    # Create a truly malformed CSV (unclosed quote)
    csv_content = "classroom_id,username\n1,\"unclosed quote\n2,another_row"

    with_temp_csv_file(csv_content) do |csv_file|
      service = @service.import_from_csv(csv_file.path)

      assert_not service.success?
      assert_match(/Invalid CSV format/, service.errors.full_messages.join)
    end
  end

  test "import_from_csv skips empty rows" do
    csv_content = "classroom_id,username\n#{@classroom1.id},student001\n,\n#{@classroom1.id},student002"

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference("Student.count", 2) do
        service = @service.import_from_csv(csv_file.path)

        assert service.success?
        assert_equal 2, service.created_count
        assert_equal %w[student001 student002], service.created_students
      end
    end
  end
end
