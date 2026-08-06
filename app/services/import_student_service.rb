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

  # A name is required here as well as on the forms, so the rule is the same however a student arrives.
  # It was optional for one commit, on the argument that an import should not drop a row it could
  # otherwise create - but that just moves the problem: a bulk-imported class is exactly where a roster of
  # lowercased usernames is least navigable, and it is the path that creates twenty-five of them at once.
  #
  # Refused as a skip_result rather than left to the model, so the import report names the row and says
  # what is missing, the same as a blank username or a duplicate.
  def call(username:, classroom_id:, name: nil)
    username = sanitize_input(username)
    classroom_id = sanitize_input(classroom_id)
    name = sanitize_input(name).presence
    return skip_result("Username is required") if username.blank?
    return skip_result("Student with username '#{username}' already exists") if Student.exists?(username: username)
    return skip_result("Classroom ID is required") if classroom_id.blank?
    # A *failure*, not a skip. The two buckets are reported differently: the controller describes skips
    # as "Skipped N existing usernames", which is true of a duplicate and a lie about a row that simply
    # has no name, while failures are reported per row as "Row N: <message>" - which is what someone
    # fixing a spreadsheet needs.
    return failure_result("Name is required") if name.blank?

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

  # For a row that is wrong before a record is built, so there is no model to read errors from.
  def failure_result(message)
    Result.new(
      success?: false,
      student: nil,
      error_message: message,
      action: :failed
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
