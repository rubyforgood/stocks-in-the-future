# frozen_string_literal: true

module CsvTestHelper
  def with_temp_csv_file(content, file_name = "test_import")
    file = Tempfile.new([file_name, ".csv"])
    file.write(content)
    file.rewind
    yield file
  ensure
    file&.unlink
  end
end
