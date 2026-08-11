# frozen_string_literal: true

module Admin
  class SchoolsController < BaseController
    before_action :set_school, only: %i[show edit update destroy]

    def index
      sort_column = params[:sort].presence || "name"
      sort_direction = params[:direction] == "desc" ? :desc : :asc

      @schools = School.reorder(sort_column => sort_direction)

      @breadcrumbs = [
        { label: "Schools" }
      ]
    end

    def show
      set_form_data

      @breadcrumbs = [
        { label: "Schools", path: admin_schools_path },
        { label: @school.name }
      ]
    end

    def new
      @school = School.new
      set_form_data
      @breadcrumbs = [
        { label: "Schools", path: admin_schools_path },
        { label: "New school" }
      ]
    end

    def edit
      set_form_data
      @breadcrumbs = [
        { label: "Schools", path: admin_schools_path },
        { label: @school.name, path: admin_school_path(@school) },
        { label: "Edit" }
      ]
    end

    def create
      @school = School.new(school_params)

      if @school.save
        redirect_to admin_school_path(@school), notice: t(".notice")
      else
        set_form_data
        @breadcrumbs = [
          { label: "Schools", path: admin_schools_path },
          { label: "New school" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    # **The name, and nothing else.** This used to rebuild `year_ids` by hand and default it to `[]`, so an
    # update with no years in the params removed every one - which, with the checkbox group gone from the
    # form, would have made *every name edit* destroy the school's years and their quarters, or 500 on the
    # first one with a classroom. The tests caught it; the assignment is gone.
    def update
      if @school.update(school_params)
        redirect_to admin_school_path(@school), notice: t(".notice")
      else
        set_form_data
        @breadcrumbs = [
          { label: "Schools", path: admin_schools_path },
          { label: @school.name, path: admin_school_path(@school) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @school.destroy
      redirect_to admin_schools_path, notice: t(".notice")
    end

    private

    def set_school
      @school = School.find(params.expect(:id))
    end

    # The school's years, for both `show` (read-only) and `edit` (with the add and remove controls). Loaded
    # here rather than queried from a view, and eager-loaded because each row states its quarter count -
    # without it that is a query per year.
    def set_form_data
      return if @school.nil?

      @school_years = @school.school_years.includes(:year, :classrooms, :quarters).to_a
      @addable_years = Year.addable_to(@school).to_a
    end

    # **No `year_ids`.** It was the mechanism behind two defects: unchecking a box silently destroyed a
    # school year and its four quarters, and doing so to a year with a classroom raised
    # `PG::ForeignKeyViolation` - a 500 - because the join was deleted before `restrict_with_error` ran.
    # Both measured. Years are added and removed through their own actions now.
    def school_params
      params.expect(school: [:name])
    end
  end
end
