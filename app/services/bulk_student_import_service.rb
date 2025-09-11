# frozen_string_literal: true

class BulkStudentImportService
  ResultWithLineNumber = Struct.new(:result, :line_number, keyword_init: true) do
    delegate_missing_to :result
  end

  def self.import_from_csv(csv_file_path)
    results = []

    CSV.foreach(csv_file_path, headers: true).with_index(2) do |row, csv_line_number|
      classroom_id = row["classroom_id"]&.strip
      username = row["username"]&.strip

      next if classroom_id.blank? || username.blank?

      result = ImportStudentService.call(
        username: username,
        classroom_id: classroom_id
      )

      results << ResultWithLineNumber.new(result: result, line_number: csv_line_number)
    end

    results
  end

  def self.generate_csv_template
    [
      "classroom_id,username",
      "1,student001",
      "1,student002",
      "2,student003"
    ].join("\n")
  end
end
