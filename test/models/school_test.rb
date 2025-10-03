# frozen_string_literal: true

require "test_helper"

class SchoolTest < ActiveSupport::TestCase
  # Factory validation
  test "factory is valid" do
    school = build(:school)
    assert school.valid?
  end

  # Validation tests
  test "is valid with valid attributes" do
    school = build(:school, name: "Test School")
    assert school.valid?
  end

  test "is invalid without a name" do
    school = build(:school, name: nil)
    assert_not school.valid?
    assert_includes school.errors[:name], "can't be blank"
  end

  test "is invalid with an empty name" do
    school = build(:school, name: "")
    assert_not school.valid?
    assert_includes school.errors[:name], "can't be blank"
  end

  test "is invalid with a name containing only whitespace" do
    school = build(:school, name: "   ")
    assert_not school.valid?
    assert_includes school.errors[:name], "can't be blank"
  end

  # Association tests
  test "has many school_years" do
    school = create(:school)
    assert_respond_to school, :school_years
  end

  test "has many years through school_years" do
    school = create(:school)
    assert_respond_to school, :years
  end

  test "can have multiple school_years" do
    school = create(:school)
    year1 = create(:year, name: "2024")
    year2 = create(:year, name: "2025")

    school_year1 = create(:school_year, school: school, year: year1)
    school_year2 = create(:school_year, school: school, year: year2)

    assert_equal 2, school.school_years.count
    assert_includes school.school_years, school_year1
    assert_includes school.school_years, school_year2
  end

  test "can access years through school_years association" do
    school = create(:school)
    year1 = create(:year, name: "2024")
    year2 = create(:year, name: "2025")

    create(:school_year, school: school, year: year1)
    create(:school_year, school: school, year: year2)

    assert_equal 2, school.years.count
    assert_includes school.years, year1
    assert_includes school.years, year2
  end

  # Dependent restrict_with_error tests
  test "cannot be destroyed when it has associated school_years" do
    school = create(:school)
    year = create(:year)
    create(:school_year, school: school, year: year)

    assert_not school.destroy
    assert_includes school.errors[:base], "Cannot delete record because dependent school years exist"
  end

  test "can be destroyed when it has no associated school_years" do
    school = create(:school)

    assert_difference("School.count", -1) do
      school.destroy!
    end
  end

  # Edge cases
  test "allows duplicate names" do
    create(:school, name: "Test School")
    duplicate_school = build(:school, name: "Test School")

    assert duplicate_school.valid?
  end

  test "name can contain special characters" do
    school = build(:school, name: "St. Mary's School & Academy")
    assert school.valid?
  end

  test "name can contain numbers" do
    school = build(:school, name: "PS 123")
    assert school.valid?
  end

  test "name can be very long" do
    long_name = "A" * 255
    school = build(:school, name: long_name)
    assert school.valid?
  end

  # Persistence tests
  test "persists name correctly" do
    school = create(:school, name: "Persisted School")
    reloaded_school = School.find(school.id)

    assert_equal "Persisted School", reloaded_school.name
  end

  test "updates name correctly" do
    school = create(:school, name: "Original Name")
    school.update!(name: "Updated Name")

    assert_equal "Updated Name", school.reload.name
  end
end
