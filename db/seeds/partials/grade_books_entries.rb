# For each quarter, spin up a GradeBook for this classroom
school_years = SchoolYear.first
classroom = Classroom.first

Quarter
  .where(school_year: school_years)
  .order(:number)
  .each do |quarter|
    book = GradeBook.find_or_create_by!(
      quarter: quarter,
      classroom: classroom
    )
    puts "Seeded GradeBook for #{quarter.name}"
    Rails.logger.info "Seeded GradeBook for #{quarter.name}"

    # And for each student in that classroom, create a blank entry
    classroom
      .users
      .where(type: "Student")
      .find_each do |student|
      GradeEntry.find_or_create_by!(
        grade_book: book,
        user: student
      )
      puts "Seeded GradeEntry for student #{student.username}"
      Rails.logger.info "Seeded GradeEntry for student #{student.username}"
    end
  end
