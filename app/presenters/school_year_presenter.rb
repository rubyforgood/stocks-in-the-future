# frozen_string_literal: true

class SchoolYearPresenter < BasePresenter
  def display_name
    "#{school_name} (#{year_name})"
  end
end
