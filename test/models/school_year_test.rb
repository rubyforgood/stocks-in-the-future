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

  test "can be destroyed and cascades quarters" do
    school_year = create(:school_year)
    quarter_ids = school_year.quarters.pluck(:id)
    assert_equal 4, quarter_ids.size

    assert school_year.destroy
    assert Quarter.where(id: quarter_ids).empty?
  end

  test "cannot be destroyed when classrooms exist" do
    school_year = create(:school_year)
    create(:classroom, school_year: school_year)

    assert_not school_year.destroy
    assert school_year.errors.added?(:base, "Cannot delete record because dependent classrooms exist")
  end

  test "cannot be destroyed when grade books exist" do
    school_year = create(:school_year)
    create(:classroom, school_year: school_year)

    assert_not school_year.destroy
  end

  test "automatically creates 4 quarters when created" do
    school = create(:school)
    year = create(:year)

    school_year = SchoolYear.create!(school: school, year: year)

    assert_equal 4, school_year.quarters.count
    assert_equal [1, 2, 3, 4], school_year.quarters.order(:number).pluck(:number)
    assert_equal ["Quarter 1", "Quarter 2", "Quarter 3", "Quarter 4"],
                 school_year.quarters.order(:number).pluck(:name)
  end
end
