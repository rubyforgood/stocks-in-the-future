# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class StudentImportService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :created_students, :skipped_students

  def initialize
    @created_students = []
    @skipped_students = []
    @system_error = false
  end

  def import_from_csv(csv_file_path)
    errors.clear
    @system_error = false

    if csv_file_path.blank?
      errors.add(:base, "CSV file path is required")
      @system_error = true
      return self
    end

    begin
      process_csv_file(csv_file_path)
    rescue CSV::MalformedCSVError => e
      errors.add(:base, "Invalid CSV format: #{e.message}")
      @system_error = true
    rescue StandardError => e
      errors.add(:base, "An error occurred: #{e.message}")
      @system_error = true
    end

    self
  end

  def success?
    !@system_error
  end

  def created_count
    @created_students.count
  end

  def skipped_count
    @skipped_students.count
  end

  def results?
    created_count.positive? || skipped_count.positive?
  end

  def flash_notice
    return "No students found in CSV file" unless results?

    messages = []
    if created_count.positive?
      messages << "Successfully created #{created_count} students: #{@created_students.join(', ')}"
    end
    if skipped_count.positive?
      messages << "Skipped #{skipped_count} existing usernames: #{@skipped_students.join(', ')}"
    end
    messages.join(". ")
  end

  def flash_alert
    return nil if errors.empty?

    "#{errors.count} errors occurred: #{errors.full_messages.join(', ')}"
  end

  class << self
    def generate_csv_template
      [
        "classroom_id,username",
        "1,student001",
        "1,student002",
        "2,student003"
      ].join("\n")
    end
  end

  private

  def process_csv_file(csv_file_path)
    line_number = 1 # Start at 1 for header
    CSV.foreach(csv_file_path, headers: true) do |row|
      line_number += 1
      process_csv_row(row, line_number)
    end
  end

  def process_csv_row(row, line_number)
    classroom_id = row["classroom_id"]&.strip
    username = row["username"]&.strip

    return if skip_empty_row?(classroom_id, username)

    if duplicate_username?(username)
      @skipped_students << username
      return
    end

    create_student(username, classroom_id, line_number)
  end

  def skip_empty_row?(classroom_id, username)
    classroom_id.blank? || username.blank?
  end

  def duplicate_username?(username)
    return false if username.blank?

    Student.exists?(username: username)
  end

  def create_student(username, classroom_id, line_number)
    return add_validation_error("Username is required", line_number) if username.blank?

    student = Student.new(
      username: username,
      classroom_id: classroom_id,
      password: FriendlyPasswordGenerator.generate
    )

    if student.save
      @created_students << username
    else
      error_message = build_detailed_error_message(student, classroom_id)
      add_validation_error(error_message, line_number)
    end
  end

  def build_detailed_error_message(student, classroom_id)
    errors = student.errors.full_messages

    errors << "Classroom ID '#{classroom_id}' not found" if student.errors[:classroom].any? && classroom_id.present?

    errors.join(", ")
  end

  def add_validation_error(message, line_number)
    errors.add(:base, "Row #{line_number}: #{message}")
  end
end
# rubocop:enable Metrics/ClassLength
