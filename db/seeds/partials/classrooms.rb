classroom = Classroom.find_or_create_by!(name: "Smith's Sixth Grade", school_year: SchoolYear.first, trading_enabled: true)
grade = Grade.find_by(level: 6)
classroom.grades << grade if grade && !classroom.grades.include?(grade)
