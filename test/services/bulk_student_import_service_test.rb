# frozen_string_literal: true

require "test_helper"

class BulkStudentImportServiceTest < ActiveSupport::TestCase
  include CsvTestHelper

  def setup
    @classroom1 = create(:classroom)
    @classroom2 = create(:classroom)
    @csv_header = "classroom_id,username"
  end

  test "import_from_csv returns array of results for successful imports" do
    csv_content = [
      @csv_header,
      "#{@classroom1.id},student001",
      "#{@classroom2.id},student002"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference("Student.count", 2) do
        results = BulkStudentImportService.import_from_csv(csv_file.path)

        assert_equal 2, results.length
        assert results.all?(&:success?)
        assert_equal %i[created created], results.map(&:action)
        assert_equal(%w[student001 student002], results.map { |item| item.student.username })
        assert_equal [2, 3], results.map(&:line_number)
      end
    end
  end

  test "import_from_csv returns mixed results for duplicates" do
    create(:student, username: "existing_user", classroom: @classroom1)

    csv_content = [
      @csv_header,
      "#{@classroom1.id},existing_user",
      "#{@classroom1.id},new_user"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference("Student.count", 1) do
        results = BulkStudentImportService.import_from_csv(csv_file.path)

        assert_equal 2, results.length
        assert_equal %i[skipped created], results.map(&:action)

        skipped_item = results.find(&:skipped?)
        created_item = results.find(&:created?)

        assert_match(/existing_user.*already exists/, skipped_item.error_message)
        assert_equal "new_user", created_item.student.username
        assert_equal [2, 3], results.map(&:line_number)
      end
    end
  end

  test "import_from_csv returns failed results for validation errors" do
    csv_content = [
      @csv_header,
      "999,invalid_classroom"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_no_difference("Student.count") do
        results = BulkStudentImportService.import_from_csv(csv_file.path)

        assert_equal 1, results.length
        item = results.first
        assert_not item.success?
        assert_equal :failed, item.action
        assert_match(/Classroom ID '999' not found/, item.error_message)
        assert_equal 2, item.line_number
      end
    end
  end

  test "import_from_csv skips empty rows and returns only valid results" do
    csv_content = [
      @csv_header,
      "#{@classroom1.id},student001",
      ",",
      "#{@classroom1.id},student002"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference("Student.count", 2) do
        results = BulkStudentImportService.import_from_csv(csv_file.path)

        assert_equal 2, results.length
        assert results.all?(&:success?)
        assert_equal(%w[student001 student002], results.map { |item| item.student.username })
        assert_equal [2, 4], results.map(&:line_number)
      end
    end
  end

  test "import_from_csv returns empty array for empty CSV" do
    csv_content = @csv_header

    with_temp_csv_file(csv_content) do |csv_file|
      results = BulkStudentImportService.import_from_csv(csv_file.path)
      assert_equal [], results
    end
  end

  test "generate_csv_template returns correct format" do
    template = BulkStudentImportService.generate_csv_template
    lines = template.split("\n")

    assert_equal "classroom_id,username", lines.first
    assert_equal 4, lines.length
  end
end
