# frozen_string_literal: true

require "csv"

class BulkGradeImportService
  ImportResult = Struct.new(:success?, :created_count, :skipped_count, :errors, keyword_init: true)

  def self.import_from_csv(file_path)
    new(file_path).import
  end

  def initialize(file_path)
    @file_path = file_path
    @created_count = 0
    @skipped_count = 0
    @errors = []
  end

  def import
    CSV.foreach(@file_path, headers: true, header_converters: :symbol) do |row|
      process_row(row)
    end

    ImportResult.new(
      success?: @errors.empty?,
      created_count: @created_count,
      skipped_count: @skipped_count,
      errors: @errors
    )
  rescue CSV::MalformedCSVError => e
    ImportResult.new(
      success?: false,
      created_count: 0,
      skipped_count: 0,
      errors: ["Invalid CSV format: #{e.message}"]
    )
  end

  private

  def process_row(row)
    school_data = SchoolData.new(row)

    unless school_data.valid?
      @errors << "Row #{$.}: Missing or invalid school data"
      @skipped_count += 1
      return
    end

    student_data = StudentData.new(row, school_data.classroom)
    grade_data = GradeData.new(row)

    unless student_data.valid?
      @errors << "Row #{$.}: Missing or invalid student name"
      @skipped_count += 1
      return
    end

    ActiveRecord::Base.transaction do
      student = student_data.find_or_create_student

      if student && student.persisted?
        add_grades_to_grade_book(student, grade_data, school_data)
        @created_count += 1
      else
        @errors << "Row #{$.}: Could not create or find student"
        @skipped_count += 1
      end
    end
  end

  def add_grades_to_grade_book(student, grade_data, school_data)
    quarters = school_data.quarters
    grades_by_quarter = [grade_data.q1_grades, grade_data.q2_grades, grade_data.q3_grades]

    grades_by_quarter.each_with_index do |grades, index|
      quarter = quarters[index]
      next unless quarter

      grade_book = school_data.grade_book_for_quarter(quarter)
      next unless grade_book

      grade_entry = GradeEntry.find_or_initialize_by(user: student, grade_book: grade_book)
      grade_entry.math_grade = grades[:math]
      grade_entry.reading_grade = grades[:reading]
      grade_entry.attendance_days = grades[:attendance]
      grade_entry.save
    end
  end

end

class StudentData
  def initialize(row, classroom)
    @first_name = row[:student_first_name]&.strip
    @last_name = row[:student_last_name]&.strip
    @classroom = classroom
  end

  def valid?
    @first_name.present? && @last_name.present?
  end

  def name
    "#{@first_name} #{@last_name}"
  end

  def find_or_create_student
    return nil if name.blank?

    # Find student by name and classroom to ensure uniqueness per classroom
    existing_student = Student.find_by(name: name, classroom: @classroom)

    return existing_student if existing_student

    # Create new student with classroom
    student = Student.new(
      name: name,
      classroom: @classroom,
      username: "temp_#{SecureRandom.hex(8)}",
      password: MemorablePasswordGenerator.generate
    )

    if student.save
      # Update username with ID
      student.username = if name.length > 8
        "#{name.downcase.gsub(/\s+/, '')[0..7]}#{student.id}"
      else
        "#{name.downcase.gsub(/\s+/, '')}#{student.id}"
      end
      student.save
    end

    student
  end
end

class GradeData
  def initialize(row)
    @row = row
  end

  def q1_grades
    { math: math_q1, reading: reading_q1, attendance: attendance_q1 }
  end

  def q2_grades
    { math: math_q2, reading: reading_q2, attendance: attendance_q2 }
  end

  def q3_grades
    { math: math_q3, reading: reading_q3, attendance: attendance_q3 }
  end

  private

  def math_q1
    @row[:math_q1]&.strip
  end

  def math_q2
    @row[:math_q2]&.strip
  end

  def math_q3
    @row[:math_q3]&.strip
  end

  def reading_q1
    @row[:reading_q1]&.strip
  end

  def reading_q2
    @row[:reading_q2]&.strip
  end

  def reading_q3
    @row[:reading_q3]&.strip
  end

  def attendance_q1
    val = @row[:attendance_q1]&.strip
    val.present? ? val.to_i : 0
  end

  def attendance_q2
    val = @row[:attendance_q2]&.strip
    val.present? ? val.to_i : 0
  end

  def attendance_q3
    val = @row[:attendance_q3]&.strip
    val.present? ? val.to_i : 0
  end
end

class SchoolData
  def initialize(row)
    @school_name = row[:school]&.strip
    @classroom_name = row[:classroom]&.strip
    @year = row[:school_year]&.strip
    @quarters = []
    @grade_books = {}

    create_quarters_and_grade_books
  end

  def school
    @school ||= find_or_create_school(@school_name)
  end

  def classroom
    @classroom ||= find_or_create_classroom(@classroom_name, school_year, school)
  end

  def school_year
    @school_year ||= find_or_create_school_year(@year, school)
  end

  def quarters
    @quarters
  end

  def grade_book_for_quarter(quarter)
    @grade_books[quarter.number]
  end

  def valid?
    school_year.present? && school.present? && classroom.present?
  end

  private

  def create_quarters_and_grade_books
    return if @year.blank? || @school_name.blank?

    # Create quarters 1, 2, 3
    (1..3).each do |quarter_number|
      quarter = Quarter.find_or_create_by!(school_year: school_year, number: quarter_number)
      @quarters << quarter

      grade_book = find_or_create_grade_book(classroom, quarter)
      @grade_books[quarter_number] = grade_book if grade_book
    end
  end

  def find_or_create_grade_book(classroom, quarter)
    return nil if classroom.nil? || quarter.nil?

    GradeBook.find_or_create_by!(classroom: classroom, quarter: quarter)
  end

  def find_or_create_school(school_name)
    return nil if school_name.blank?

    School.find_or_create_by!(name: school_name)
  end

  def find_or_create_school_year(year_name, school)
    return nil if year_name.blank? || school.nil?

    year = Year.find_or_create_by!(name: year_name)
    SchoolYear.find_or_create_by!(school: school, year: year)
  end

  def find_or_create_classroom(classroom_name, school_year_record, school)
    return nil if classroom_name.blank? || school_year_record.nil?

    Classroom.find_or_create_by!(name: classroom_name, school_year: school_year_record)
  end
end
