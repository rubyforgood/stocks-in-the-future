# frozen_string_literal: true

require "test_helper"

class BulkStudentImportServiceTest < ActiveSupport::TestCase
  include CsvTestHelper

  def setup
    @classroom = create(:classroom)
    @csv_header = "classroom_id,username"
  end

  test "parses CSV and calls ImportStudentService for each valid row" do
    csv_content = [
      @csv_header,
      "#{@classroom.id},student001",
      "#{@classroom.id},student002"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      results = BulkStudentImportService.import_from_csv(csv_file.path)

      assert_equal 2, results.length
      assert_equal [2, 3], results.map(&:line_number)
      assert(results.all? { |item| item.respond_to?(:created?) })
    end
  end

  test "skips empty rows and processes only valid rows" do
    csv_content = [
      @csv_header,
      "#{@classroom.id},student001",
      ",",
      "  ,  ",
      "#{@classroom.id},student002"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      results = BulkStudentImportService.import_from_csv(csv_file.path)

      assert_equal 2, results.length
      assert_equal [2, 5], results.map(&:line_number)
    end
  end

  test "handles malformed CSV files" do
    csv_content = "classroom_id,username\n1,\"unclosed quote\n2,another_row"

    with_temp_csv_file(csv_content) do |csv_file|
      assert_raises(CSV::MalformedCSVError) do
        BulkStudentImportService.import_from_csv(csv_file.path)
      end
    end
  end

  test "returns empty array for CSV with no data rows" do
    csv_content = @csv_header

    with_temp_csv_file(csv_content) do |csv_file|
      results = BulkStudentImportService.import_from_csv(csv_file.path)
      assert_equal [], results
    end
  end

  test "returns empty array for CSV with only empty rows" do
    csv_content = [
      @csv_header,
      ",",
      "  ,  "
    ].join("\n")

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
