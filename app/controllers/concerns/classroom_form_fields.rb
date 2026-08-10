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

  # `school_id` and `year_id` are form fields, not columns - `classrooms` has a `school_year_id`. The
  # pair is found or created, so an admin does not have to go and make a SchoolYear row before they can
  # make a classroom in a year that has not been used yet.
  def assign_school_year_to_classroom
    return if classroom_params[:school_id].blank? || classroom_params[:year_id].blank?

    school = School.find(classroom_params[:school_id])
    year = Year.find(classroom_params[:year_id])
    @classroom.school_year = SchoolYear.find_or_create_by!(school:, year:)
  end

  # Pundit's filtered params, minus the two that are not columns.
  #
  # `permitted_attributes` on both sides, so the admin half stops maintaining its own list. Its list had
  # already diverged: it permitted `school_year_id` and nothing else about placement, and never permitted
  # `teacher_ids`, so the admin screens could not assign a teacher to a classroom at all.
  def classroom_attributes
    classroom_params.except(:school_id, :year_id)
  end
end
