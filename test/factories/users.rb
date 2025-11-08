# frozen_string_literal: true

FactoryBot.define do
  factory :admin, class: "User" do
    classroom { create(:classroom) }
    password { "Passw0rd" }
    sequence(:username) { |n| "admin_#{n}" }
    sequence(:email) { |n| "admin_#{n}@example.com" }
    admin { true }
  end

  factory :student, class: "Student" do
    type { "Student" }
    password { "Passw0rd" }
    classroom { create(:classroom) }
    sequence(:username) { |n| "student_#{n}" }
    sequence(:email) { |n| "student_#{n}@example.com" }

    after(:create) do |student, evaluator|
      if student.classroom && !student.student_classrooms.exists?(classroom: student.classroom)
        student.student_classrooms.create!(classroom: student.classroom)
      end
    end
  end

  factory :teacher, class: "Teacher" do
    type { "Teacher" }
    password { "Passw0rd" }
    classroom { create(:classroom) }
    sequence(:username) { |n| "teacher_#{n}" }
    sequence(:email) { |n| "teacher_#{n}@example.com" }
  end
end
