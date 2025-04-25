# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

@year = Year.create(year: 2024)

@school = School.create(name: "Test School", years: [@year])

@classroom = Classroom.create(name: "Test Class", year: @year, school: @school)

@user = User.create(username: "test", password: "password", password_confirmation: "password", classroom: @classroom)
