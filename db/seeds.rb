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

user = User.find_or_initialize_by(username: "test")
if user.new_record?
  user.password = "password"
  user.password_confirmation = "password"
  user.classroom = classroom
  user.save!
end
