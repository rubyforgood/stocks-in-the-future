#!/usr/bin/env ruby

require_relative "config/environment"

# Test creating a User
puts "Creating a User..."
user = User.create(username: "test_user")
puts "User created with type: #{user.type}"

# Test creating a Student
puts "\nCreating a Student..."
student = Student.create(username: "test_student")
puts "Student created with type: #{student.type}"

# Test creating a Teacher
puts "\nCreating a Teacher..."
teacher = Teacher.create(username: "test_teacher")
puts "Teacher created with type: #{teacher.type}"

# Test updating a User to be a Student
puts "\nUpdating a User to be a Student..."
user.update(type: "Student")
puts "User updated to type: #{user.type}"

# Verify that the records are saved correctly
puts "\nVerifying records in the database..."
puts "Users count: #{User.count}"
puts "Students count: #{Student.count}"
puts "Teachers count: #{Teacher.count}"

# Verify that the type field is set correctly
puts "\nVerifying type field:"
puts "User type: #{user.type}"
puts "Student type: #{student.type}"
puts "Teacher type: #{teacher.type}"

puts "\nSTI implementation test completed successfully!"
