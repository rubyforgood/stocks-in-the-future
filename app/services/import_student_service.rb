# frozen_string_literal: true

class ImportStudentService
  Result = Struct.new(:success?, :student, :error_message, :action, keyword_init: true) do
    def created?
      action == :created
    end

    def skipped?
      action == :skipped
    end

    def failed?
      action == :failed
    end
  end

  def self.call(username:, classroom_id:)
    new.call(username: username, classroom_id: classroom_id)
  end

  def call(username:, classroom_id:)
    username = username&.to_s&.strip
    classroom_id = classroom_id&.to_s&.strip

    early_result = check_preconditions(username)
    return early_result if early_result

    student = create_student(username, classroom_id)
    build_result_for_student(student, classroom_id)
  end

  private

  def check_preconditions(username)
    return skip_result("Username is required") if username.blank?
    return skip_result("Student with username '#{username}' already exists") if duplicate_username?(username)

    nil
  end

  def build_result_for_student(student, classroom_id)
    if student.persisted?
      success_result(student)
    else
      error_result(student, classroom_id)
    end
  end

  def duplicate_username?(username)
    Student.exists?(username: username)
  end

  def create_student(username, classroom_id)
    Student.create(
      username: username,
      classroom_id: classroom_id,
      password: FriendlyPasswordGenerator.generate
    )
  end

  def success_result(student)
    Result.new(
      success?: true,
      student: student,
      error_message: nil,
      action: :created
    )
  end

  def skip_result(message)
    Result.new(
      success?: true,
      student: nil,
      error_message: message,
      action: :skipped
    )
  end

  def error_result(student, classroom_id)
    error_message = build_detailed_error_message(student, classroom_id)
    Result.new(
      success?: false,
      student: student,
      error_message: error_message,
      action: :failed
    )
  end

  def build_detailed_error_message(student, classroom_id)
    errors = student.errors.full_messages

    errors << "Classroom ID '#{classroom_id}' not found" if student.errors[:classroom].any? && classroom_id.present?

    errors.join(", ")
  end
end
