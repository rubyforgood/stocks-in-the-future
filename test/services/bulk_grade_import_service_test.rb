# frozen_string_literal: true

require "test_helper"

class BulkGradeImportServiceTest < ActiveSupport::TestCase
  include CsvTestHelper

  def setup
    @school = create(:school, name: "Lincoln Elementary")
    @year = create(:year, name: "2024-2025")
    @school_year = create(:school_year, school: @school, year: @year)
    @classroom = create(:classroom, name: "Room 101", school_year: @school_year)

    # Create quarters and grade books
    @q1 = create(:quarter, school_year: @school_year, number: 1)
    @q2 = create(:quarter, school_year: @school_year, number: 2)
    @q3 = create(:quarter, school_year: @school_year, number: 3)

    @grade_book_q1 = create(:grade_book, classroom: @classroom, quarter: @q1)
    @grade_book_q2 = create(:grade_book, classroom: @classroom, quarter: @q2)
    @grade_book_q3 = create(:grade_book, classroom: @classroom, quarter: @q3)

    @csv_header = "school,school_year,classroom,student_first_name,student_last_name,math_q1,math_q2,math_q3,reading_q1,reading_q2,reading_q3,attendance_q1,attendance_q2,attendance_q3"
  end

  test "imports valid CSV with all required fields" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert result.success?
      assert_equal 1, result.created_count
      assert_equal 0, result.skipped_count
      assert_empty result.errors

      student = User.find_by(name: "John Doe")
      assert_not_nil student
      assert_equal @classroom, student.classroom
    end
  end

  test "imports multiple students from CSV" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19",
      "Lincoln Elementary,2024-2025,Room 101,Jane,Smith,B+,A,A,A,A+,A,20,20,20"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert result.success?
      assert_equal 2, result.created_count
      assert_equal 0, result.skipped_count

      assert User.exists?(name: "John Doe")
      assert User.exists?(name: "Jane Smith")
    end
  end

  test "creates new school if it doesn't exist" do
    csv_content = [
      @csv_header,
      "Washington Middle,2024-2025,Room 202,Emily,Davis,A+,A,A-,A,A,A-,19,20,18"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference "School.count", 1 do
        BulkGradeImportService.import_from_csv(csv_file.path)
      end

      assert School.exists?(name: "Washington Middle")
    end
  end

  test "creates new school year if it doesn't exist" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2025-2026,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference "Year.count", 1 do
        assert_difference "SchoolYear.count", 1 do
          BulkGradeImportService.import_from_csv(csv_file.path)
        end
      end

      year = Year.find_by(name: "2025-2026")
      assert_not_nil year
      assert SchoolYear.exists?(school: @school, year: year)
    end
  end

  test "creates new classroom if it doesn't exist" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 999,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference "Classroom.count", 1 do
        BulkGradeImportService.import_from_csv(csv_file.path)
      end

      assert Classroom.exists?(name: "Room 999", school_year: @school_year)
    end
  end

  test "creates quarters and grade books for new school year" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2025-2026,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference "Quarter.count", 3 do
        assert_difference "GradeBook.count", 3 do
          BulkGradeImportService.import_from_csv(csv_file.path)
        end
      end
    end
  end

  test "finds existing student by name and classroom" do
    existing_student = create(:student, name: "John Doe", classroom: @classroom)

    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_no_difference "User.count" do
        result = BulkGradeImportService.import_from_csv(csv_file.path)
        assert result.success?
        assert_equal 1, result.created_count
      end

      # Should still be the same student
      assert_equal existing_student.id, User.find_by(name: "John Doe", classroom: @classroom).id
    end
  end

  test "creates grade entries for all three quarters" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      assert_difference "GradeEntry.count", 3 do
        BulkGradeImportService.import_from_csv(csv_file.path)
      end

      student = User.find_by(name: "John Doe")

      # Check Q1 grades
      q1_entry = GradeEntry.find_by(user: student, grade_book: @grade_book_q1)
      assert_not_nil q1_entry
      assert_equal "A", q1_entry.math_grade
      assert_equal "A-", q1_entry.reading_grade
      assert_equal 18, q1_entry.attendance_days

      # Check Q2 grades
      q2_entry = GradeEntry.find_by(user: student, grade_book: @grade_book_q2)
      assert_not_nil q2_entry
      assert_equal "A-", q2_entry.math_grade
      assert_equal "B+", q2_entry.reading_grade
      assert_equal 20, q2_entry.attendance_days

      # Check Q3 grades
      q3_entry = GradeEntry.find_by(user: student, grade_book: @grade_book_q3)
      assert_not_nil q3_entry
      assert_equal "B+", q3_entry.math_grade
      assert_equal "B", q3_entry.reading_grade
      assert_equal 19, q3_entry.attendance_days
    end
  end

  test "skips row with blank first name" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert_not result.success?
      assert_equal 0, result.created_count
      assert_equal 1, result.skipped_count
      assert_not_empty result.errors
    end
  end

  test "skips row with blank last name" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert_not result.success?
      assert_equal 0, result.created_count
      assert_equal 1, result.skipped_count
      assert_not_empty result.errors
    end
  end

  test "skips row with blank school" do
    csv_content = [
      @csv_header,
      ",2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert_not result.success?
      assert_equal 0, result.created_count
      assert_equal 1, result.skipped_count
    end
  end

  test "skips row with blank school year" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert_not result.success?
      assert_equal 0, result.created_count
      assert_equal 1, result.skipped_count
    end
  end

  test "skips row with blank classroom" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert_not result.success?
      assert_equal 0, result.created_count
      assert_equal 1, result.skipped_count
    end
  end

  test "handles malformed CSV files" do
    csv_content = "school,school_year,classroom\n\"unclosed quote\n"

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert_not result.success?
      assert_equal 0, result.created_count
      assert_equal 0, result.skipped_count
      assert_includes result.errors.first, "Invalid CSV format"
    end
  end

  test "returns success for empty CSV" do
    csv_content = @csv_header

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert result.success?
      assert_equal 0, result.created_count
      assert_equal 0, result.skipped_count
      assert_empty result.errors
    end
  end

  test "processes partial success with some invalid rows" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19",
      "Lincoln Elementary,2024-2025,Room 101,,Invalid,A,A-,B+,A-,B+,B,18,20,19",
      "Lincoln Elementary,2024-2025,Room 101,Jane,Smith,B+,A,A,A,A+,A,20,20,20"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert_not result.success?
      assert_equal 2, result.created_count
      assert_equal 1, result.skipped_count
      assert_equal 1, result.errors.length
    end
  end

  test "strips whitespace from CSV fields" do
    csv_content = [
      @csv_header,
      "  Lincoln Elementary  ,  2024-2025  ,  Room 101  ,  John  ,  Doe  ,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert result.success?

      student = User.find_by(name: "John Doe")
      assert_not_nil student
    end
  end

  test "assigns student to correct classroom" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      BulkGradeImportService.import_from_csv(csv_file.path)

      student = User.find_by(name: "John Doe")
      assert_equal @classroom.id, student.classroom_id
    end
  end


  test "handles nil grades gracefully" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,,,,,,,,,,"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      # Should still create student even if grades are nil
      assert result.success?
      assert_equal 1, result.created_count

      student = User.find_by(name: "John Doe")
      assert_not_nil student

      # Grade entries should be created with nil values
      q1_entry = GradeEntry.find_by(user: student, grade_book: @grade_book_q1)
      assert_not_nil q1_entry
      assert_nil q1_entry.math_grade
      assert_nil q1_entry.reading_grade
      assert_equal 0, q1_entry.attendance_days
    end
  end

  test "generates unique username for new student" do
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      BulkGradeImportService.import_from_csv(csv_file.path)

      student = User.find_by(name: "John Doe")
      assert_not_nil student.username
      assert_match(/johndoe\d+/, student.username)
    end
  end

  test "does not create duplicate student in same classroom" do
    # Create student first
    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      BulkGradeImportService.import_from_csv(csv_file.path)
    end

    original_student = User.find_by(name: "John Doe", classroom: @classroom)
    original_count = User.count

    # Import same student again
    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert result.success?
      assert_equal 1, result.created_count
      assert_equal original_count, User.count # No new user created

      # Should be the same student
      student = User.find_by(name: "John Doe", classroom: @classroom)
      assert_equal original_student.id, student.id
    end
  end

  test "allows same name in different classrooms" do
    classroom2 = create(:classroom, name: "Room 102", school_year: @school_year)

    # Reuse existing quarters, just create grade books for classroom2
    create(:grade_book, classroom: classroom2, quarter: @q1)
    create(:grade_book, classroom: classroom2, quarter: @q2)
    create(:grade_book, classroom: classroom2, quarter: @q3)

    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19",
      "Lincoln Elementary,2024-2025,Room 102,John,Doe,B,B,B,B,B,B,15,15,15"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert result.success?
      assert_equal 2, result.created_count
      assert_equal 2, User.where(name: "John Doe").count

      # Verify they're in different classrooms
      students = User.where(name: "John Doe").to_a
      assert_includes students.map(&:classroom_id), @classroom.id
      assert_includes students.map(&:classroom_id), classroom2.id
    end
  end

  test "allows same name in different school years" do
    year2 = create(:year, name: "2025-2026")
    school_year2 = create(:school_year, school: @school, year: year2)
    classroom2 = create(:classroom, name: "Room 101", school_year: school_year2)

    # Create quarters and grade books for the new school year
    q1_sy2 = create(:quarter, school_year: school_year2, number: 1)
    q2_sy2 = create(:quarter, school_year: school_year2, number: 2)
    q3_sy2 = create(:quarter, school_year: school_year2, number: 3)
    create(:grade_book, classroom: classroom2, quarter: q1_sy2)
    create(:grade_book, classroom: classroom2, quarter: q2_sy2)
    create(:grade_book, classroom: classroom2, quarter: q3_sy2)

    csv_content = [
      @csv_header,
      "Lincoln Elementary,2024-2025,Room 101,John,Doe,A,A-,B+,A-,B+,B,18,20,19",
      "Lincoln Elementary,2025-2026,Room 101,John,Doe,B,B,B,B,B,B,15,15,15"
    ].join("\n")

    with_temp_csv_file(csv_content) do |csv_file|
      result = BulkGradeImportService.import_from_csv(csv_file.path)

      assert result.success?
      assert_equal 2, result.created_count
      assert_equal 2, User.where(name: "John Doe").count

      # Verify they're in different classrooms (which have different school years)
      students = User.where(name: "John Doe").to_a
      school_years = students.map { |s| s.classroom.school_year }
      assert_includes school_years, @school_year
      assert_includes school_years, school_year2
    end
  end
end
