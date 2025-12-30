# frozen_string_literal: true

class ClassroomPresenter < BasePresenter
  def display_name
    if grades_display.present?
      "#{name} (#{grades_display})"
    else
      name
    end
  end
end
