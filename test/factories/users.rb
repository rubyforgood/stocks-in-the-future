# frozen_string_literal: true

FactoryBot.define do
  factory :admin, class: "User" do
    password { "Passw0rd" }
    sequence(:username) { |n| "admin_#{n}" }
    sequence(:email) { |n| "admin_#{n}@example.com" }
    admin { true }
  end

  factory :student, class: "Student" do
    type { "Student" }
    password { "Passw0rd" }
    classroom { create(:classroom, :with_trading) }
    # Required on create, so every student built here has one - which is also closer to real data than a
    # nameless student was. A test that needs one without a name sets `name: nil` and saves with
    # `validate: false`, or uses the :nameless trait.
    sequence(:name) { |n| "Student #{n} Example" }
    sequence(:username) { |n| "student_#{n}" }
    sequence(:email) { |n| "student_#{n}@example.com" }

    # Idempotent, because `Student` has `after_create :ensure_portfolio` - so this trait was creating a
    # **second** portfolio row for the same student. `has_one` does not prevent that; it only decides
    # which row the association returns, which means a test could deposit into one and read the other.
    # It also doubled any count of portfolios: three students measured as six.
    trait :with_portfolio do
      after(:create) do |student|
        create(:portfolio, user: student) if student.portfolio.blank?
      end
    end

    # For the case the validation deliberately still allows: a student who predates the requirement.
    trait :nameless do
      to_create { |student| student.save(validate: false) }
      name { nil }
    end

    trait :without_enrollment do
      classroom { nil }
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end

  factory :teacher, class: "Teacher" do
    type { "Teacher" }
    password { "Passw0rd" }
    classroom { create(:classroom) }
    sequence(:email) { |n| "teacher_#{n}@example.com" }
  end
end
