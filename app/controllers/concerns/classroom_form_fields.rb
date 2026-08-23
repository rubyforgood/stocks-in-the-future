# frozen_string_literal: true

# The data and the parameter handling behind `classrooms/_form`, shared by the two controllers that
# render it.
#
# `/classrooms/new` and `/admin/classrooms/new` were two different forms for one model: this one asks
# for a school and a year and offers the teacher assignment, the admin one asked for a single school
# year and offered no teachers. They render one partial now, which only works if both controllers agree
# about what that partial posts - so the agreement lives here rather than being written out twice.
module ClassroomFormFields
  extend ActiveSupport::Concern

  private

  # The three collections the form's selects and fieldsets need. The admin half set none of them and
  # queried inline from the view instead, which is also why its dropdowns were different: `Grade.all`
  # against the app's `Classroom::GRADE_RANGE`, and a flat list of SchoolYears against a school and a
  # year chosen separately.
  def classroom_form_data
    @schools = School.order(:name)
    @years = Year.order(:name)
    @teachers = Teacher.all.sort_by(&:display_name)
  end

  # `school_id` and `year_id` are handled by `SchoolYearFields` on the model: they are virtual
  # attributes there, resolved into a SchoolYear on validation, so the controllers pass them straight
  # through. This used to be a controller method that found-or-created the row *before* save, which left
  # an orphan SchoolYear behind every failed submit and put the resulting error on an association neither
  # form has a field for.
end
