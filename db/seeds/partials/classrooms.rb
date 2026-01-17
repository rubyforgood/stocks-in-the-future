# frozen_string_literal: true

grade = Grade.find_by!(level: 6)
classroom = Classroom.find_or_initialize_by(name: "Smith's Sixth Grade", school_year: SchoolYear.first)
classroom.trading_enabled = true
classroom.grades << grade unless classroom.grades.include?(grade)
classroom.save!
