# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

year = Year.find_or_create_by(name: "2024")
(2024...2036).each do |i|
  year = Year.find_or_create_by(name: "#{i} - #{i + 1}")
  year.save!
end

school = School.find_or_create_by(name: "Test School")

school_year_instance = SchoolYear.find_or_create_by!(school: school, year: year)

classroom = Classroom.find_or_create_by(name: "Smith's Sixth Grade", school_year: school_year_instance)

# Clear existing users to ensure idempotency
User.destroy_all

# Create users with usernames and admin flag
Teacher.create!(
  username: "Teacher",
  email: "teacher@example.com",
  password: "password",
  password_confirmation: "password",
  admin: false,
  classroom: classroom
)

Student.create!(
  username: "Student",
  email: "student@example.com",
  password: "password",
  password_confirmation: "password",
  admin: false,
  classroom: classroom,
  portfolio_attributes: { current_position: 10_000.0 }
)

User.create!(
  username: "Admin",
  email: "admin@example.com",
  password: "password",
  password_confirmation: "password",
  admin: true,
  classroom: classroom
)

Rails.logger.info "Seeded 3 users: Teacher, Student, and Admin"

# load and run seed files for other models:
Rails.root.glob("db/seeds/*.rb").each do |seed_file|
  load seed_file
end

# Ensure exactly four quarters (number + name) exist for this school year
(1..4).each do |n|
  quarter = Quarter.find_or_create_by!(
    school_year: school_year_instance,
    number: n
  ) do |q|
    # adjust naming as you prefer
    q.name = "Q#{n} - #{school_year_instance.year.name}"
  end

  Rails.logger.info "Seeded Quarter: #{quarter.name}"
end

# For each quarter, spin up a GradeBook for this classroom
Quarter
  .where(school_year: school_year_instance)
  .order(:number)
  .each do |quarter|
    book = GradeBook.find_or_create_by!(
      quarter: quarter,
      classroom: classroom
    )
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
      Rails.logger.info "Seeded GradeEntry for student #{student.username}"
    end
  end
