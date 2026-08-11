# frozen_string_literal: true

module Admin
  module Schools
    # Adding a year to a school, and taking one away.
    #
    # **Why this is not a multi-select on the school form.** Each of these is a provisioning action: creating
    # a `SchoolYear` writes four quarters, and destroying one takes them with it. The form used `year_ids=`,
    # so unchecking a box silently destroyed four quarters - and, when the year had a classroom, raised
    # `PG::ForeignKeyViolation` rather than saying no, because the join was deleted before
    # `restrict_with_error` could run. Both measured.
    #
    # A native multi-select would not have helped: GOV.UK advises against `select multiple` outright, and
    # Polaris, Material and Carbon ship none. What the field does for this is what this does - PowerSchool's
    # per-school Years and Terms, Infinite Campus's per-year calendar: one explicit action, because a year is
    # something you set up rather than a preference you tick.
    class SchoolYearsController < Admin::BaseController
      before_action :set_school

      def create
        school_year = @school.school_years.new(year_id: params[:year_id])

        if school_year.save
          redirect_to admin_school_path(@school),
                      notice: t(".notice", year: school_year.year_name, count: school_year.quarters.count)
        else
          redirect_to admin_school_path(@school), alert: school_year.errors.full_messages.to_sentence
        end
      end

      def destroy
        school_year = @school.school_years.find(params.expect(:id))

        # Asked here rather than left to the association's `restrict_with_error`, so the message can name the
        # number of classrooms: "it still has 3 classrooms" is actionable and "cannot be destroyed" is not.
        return refuse(school_year) unless school_year.removable?

        year = school_year.year_name
        quarters = school_year.quarters.count
        school_year.destroy!

        redirect_to admin_school_path(@school), notice: t(".notice", year: year, count: quarters)
      end

      private

      def refuse(school_year)
        redirect_to admin_school_path(@school),
                    alert: t(
                      "admin.schools.school_years.destroy.has_classrooms",
                      year: school_year.year_name, count: school_year.classrooms.count
                    )
      end

      def set_school
        @school = School.find(params.expect(:school_id))
      end
    end
  end
end
