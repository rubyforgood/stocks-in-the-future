# frozen_string_literal: true

class ImportStudentService
  Result = Struct.new(:success?, :student, :error_message, :action) do
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

  def self.call(username:, classroom_id:, name: nil)
    new.call(username: username, classroom_id: classroom_id, name: name)
  end

  # name is optional here and required on the forms, deliberately. A student typed in by hand must have
  # one - a roster of lowercased usernames is guesswork - but an import that cannot supply a name should
  # still create the student rather than dropping the row, so the CSV column is offered and not demanded.
  def call(username:, classroom_id:, name: nil)
    username = sanitize_input(username)
    classroom_id = sanitize_input(classroom_id)
    name = sanitize_input(name).presence
    return skip_result("Username is required") if username.blank?
    return skip_result("Student with username '#{username}' already exists") if Student.exists?(username: username)
    return skip_result("Classroom ID is required") if classroom_id.blank?

    import_student(username: username, classroom_id: classroom_id, name: name)
  end

  private

  def sanitize_input(input)
    input&.to_s&.strip
  end

  def import_student(username:, classroom_id:, name: nil)
    student = Student.new(
      name: name,
      username: username,
      classroom_id: classroom_id,
      password: MemorablePasswordGenerator.generate
    )

    if student.save
      success_result(student)
    else
      error_result(student)
    end
  rescue ActiveRecord::InvalidForeignKey
    student.errors.add(:classroom, "can't be blank")
    error_result(student)
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
