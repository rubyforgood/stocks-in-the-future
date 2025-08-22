# Teacher
teacher = User.find_or_initialize_by(email: "teacher@example.com")
unless teacher.persisted?
  teacher.attributes = {
    username: "Teacher",
    password: "password",
    password_confirmation: "password",
    admin: false,
    type: "Teacher",
    classroom: Classroom.first
  }
  teacher.save
  puts "Created Teacher user: #{teacher.email}"
  Rails.logger.info "Seeded Teacher user: #{teacher.email}"
else
  puts "Teacher user already exists: #{teacher.email}"
end

# Student
student = User.find_or_initialize_by(email: "student@example.com")
unless student.persisted?
  student.attributes = {
    username: "Student",
    password: "password",
    password_confirmation: "password",
    admin: false,
    type: "Student",
    classroom: Classroom.first,
    portfolio_attributes: { current_position: 10_000.0 }
  }
  student.save
  puts "Created Student user: #{student.email}"
  Rails.logger.info "Seeded Student user: #{student.email}"
else
  puts "Student user already exists: #{student.email}"
end

# Admin
admin = User.find_or_initialize_by(email: "admin@example.com")
unless admin.persisted?
  admin.attributes = {
    username: "Admin",
    password: "password",
    password_confirmation: "password",
    admin: true,
    type: "User",
    classroom: Classroom.first
  }
  admin.save
  puts "Created Admin user: #{admin.email}"
  Rails.logger.info "Seeded Admin user: #{admin.email}"
else
  puts "Admin user already exists: #{admin.email}"
end

# Student "mike" to who the portfolio transactions will belong
mike = User.find_or_initialize_by(email: "mike@example.com")
unless mike.persisted?
  mike.attributes = {
    username: "mike",
    email: "mike@example.com",
    password: "password",
    password_confirmation: "password",
    admin: false,
    type: "Student",
    classroom: Classroom.first,
    portfolio_attributes: { current_position: 10_000.0 }
  }
  mike.save
  puts "Created portfolio transactions user: #{mike.email}"
  Rails.logger.info "Seeded user: #{mike.email}"
else
  puts "Mike already exists: #{mike.email}"
end
