# frozen_string_literal: true

class SchoolYearCreationService
  def initialize(school:, year:)
    @school = school
    @year = year
  end

  def call
    ActiveRecord::Base.transaction do
      school_year = SchoolYear.create!(school: @school, year: @year)
      (1..4).each do |quarter_number|
        Quarter.create!(name: "Quarter #{quarter_number}", school_year: school_year, number: quarter_number)
      end
      school_year
    end
  end
end
