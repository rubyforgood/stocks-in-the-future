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
    username = sanitize_input(username)
    classroom_id = sanitize_input(classroom_id)
    return skip_result("Username is required") if username.blank?
    return skip_result("Student with username '#{username}' already exists") if Student.exists?(username: username)
    return skip_result("Classroom ID is required") if classroom_id.blank?

    import_student(username: username, classroom_id: classroom_id)
  end

  private

  def sanitize_input(input)
    input&.to_s&.strip
  end

  def import_student(username:, classroom_id:)
    student = Student.new(
      username: username,
      password: MemorablePasswordGenerator.generate
    )

    # Build the enrollment association before saving
    student.enrollments.build(classroom_id: classroom_id)

    if student.save
      success_result(student)
    else
      error_result(student)
    end
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

  def error_result(student)
    Result.new(
      success?: false,
      student: student,
      error_message: student.errors.full_messages.join(", "),
      action: :failed
    )
  end
end
