# frozen_string_literal: true

require "test_helper"

class SchoolYearTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:school_year).validate!
  end

  test "can be destroyed when no associations exist" do
    school_year = create(:school_year)
    assert school_year.destroy
  end

  test "cannot be destroyed when classrooms exist" do
    school_year = create(:school_year)
    create(:classroom, school_year: school_year)

    assert_not school_year.destroy
    assert school_year.errors.added?(:base, "Cannot delete record because dependent classrooms exist")
  end

  test "cannot be destroyed when quarters exist" do
    school_year = create(:school_year)
    create(:quarter, school_year: school_year)

    assert_not school_year.destroy
    assert school_year.errors.added?(:base, "Cannot delete record because dependent quarters exist")
  end
end
