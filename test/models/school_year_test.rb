# frozen_string_literal: true

require "test_helper"

class SchoolYearTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:school_year).validate!
  end

  test "name returns school name and year name" do
    school_year = build(:school_year)
    assert_equal "#{school_year.school_name} (#{school_year.year_name})", school_year.name
  end

  test "creates 4 quarters after creation" do
    assert_difference("Quarter.count", 4) do
      create(:school_year)
    end
  end

  test "quarters are numbered 1 through 4 after creation" do
    school_year = create(:school_year)
    assert_equal [1, 2, 3, 4], school_year.quarters.order(:number).pluck(:number)
  end

  test "cannot be destroyed because quarters are always present" do
    school_year = create(:school_year)

    assert_not school_year.destroy
    assert school_year.errors.added?(:base, "Cannot delete record because dependent quarters exist")
  end

  test "cannot be destroyed when classrooms exist" do
    school_year = create(:school_year)
    create(:classroom, school_year: school_year)

    assert_not school_year.destroy
    assert school_year.errors.added?(:base, "Cannot delete record because dependent classrooms exist")
  end
end
