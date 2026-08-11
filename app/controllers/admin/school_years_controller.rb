# frozen_string_literal: true

module Admin
  class SchoolYearsController < BaseController
    before_action :set_school_year, only: %i[show edit update destroy]

    def index
      @school_years = apply_sorting(SchoolYear.includes(:school, :year), default: "id")

      @breadcrumbs = [
        { label: "School years" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "School years", path: admin_school_years_path },
        { label: @school_year.to_s }
      ]
    end

    def new
      @school_year = SchoolYear.new

      @breadcrumbs = [
        { label: "School years", path: admin_school_years_path },
        { label: "New school year" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "School years", path: admin_school_years_path },
        { label: @school_year.to_s, path: admin_school_year_path(@school_year) },
        { label: "Edit" }
      ]
    end

    # **One path, and the model decides.** This used to look the school and the year up by hand, call
    # `create!`, and then rescue `RecordNotUnique` to synthesise a base error saying the pair already exists.
    # `SchoolYear` validates that now - it had to, because the same rule is reached from a school's own page -
    # so the database error is unreachable from here and the hand-built message was a second copy of one
    # rule. A missing school or year is caught by `belongs_to`, which is required by default.
    def create
      @school_year = SchoolYear.new(school_year_params)

      if @school_year.save
        redirect_to admin_school_year_path(@school_year), notice: t(".notice")
      else
        render_new_with_errors
      end
    end

    def update
      if @school_year.update(school_year_params)
        redirect_to admin_school_year_path(@school_year), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "School years", path: admin_school_years_path },
          { label: @school_year.to_s, path: admin_school_year_path(@school_year) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @school_year.destroy
        redirect_to admin_school_years_path, notice: t(".notice")
      else
        redirect_to admin_school_years_path, alert: t(".delete_restricted")
      end
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to admin_school_years_path, alert: t(".delete_restricted")
    end

    private

    def set_school_year
      @school_year = SchoolYear.find(params.expect(:id))
    end

    def school_year_params
      params.expect(school_year: %i[school_id year_id])
    end

    def render_new_with_errors
      @breadcrumbs = [
        { label: "School years", path: admin_school_years_path },
        { label: "New school year" }
      ]
      render :new, status: :unprocessable_content
    end
  end
end
