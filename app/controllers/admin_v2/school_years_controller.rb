# frozen_string_literal: true

module AdminV2
  class SchoolYearsController < BaseController
    before_action :set_school_year, only: %i[show edit update destroy]

    def index
      @school_years = apply_sorting(SchoolYear.includes(:school, :year), default: "id")

      @breadcrumbs = [
        { label: "School Years" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "School Years", path: admin_v2_school_years_path },
        { label: @school_year.to_s }
      ]
    end

    def new
      @school_year = SchoolYear.new

      @breadcrumbs = [
        { label: "School Years", path: admin_v2_school_years_path },
        { label: "New School Year" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "School Years", path: admin_v2_school_years_path },
        { label: @school_year.to_s, path: admin_v2_school_year_path(@school_year) },
        { label: "Edit" }
      ]
    end

    def create
      school = School.find(school_year_params[:school_id])
      year = Year.find(school_year_params[:year_id])

      @school_year = SchoolYearCreationService.new(school: school, year: year).call

      if @school_year.persisted?
        redirect_to admin_v2_school_year_path(@school_year), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "School Years", path: admin_v2_school_years_path },
          { label: "New School Year" }
        ]
        render :new, status: :unprocessable_content
      end
    rescue ActiveRecord::RecordInvalid => e
      @school_year = e.record
      @breadcrumbs = [
        { label: "School Years", path: admin_v2_school_years_path },
        { label: "New School Year" }
      ]
      render :new, status: :unprocessable_content
    end

    def update
      if @school_year.update(school_year_params)
        redirect_to admin_v2_school_year_path(@school_year), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "School Years", path: admin_v2_school_years_path },
          { label: @school_year.to_s, path: admin_v2_school_year_path(@school_year) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @school_year.destroy
      redirect_to admin_v2_school_years_path, notice: t(".notice")
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to admin_v2_school_year_path(@school_year), alert: t(".delete_restricted")
    end

    private

    def set_school_year
      @school_year = SchoolYear.find(params.expect(:id))
    end

    def school_year_params
      params.expect(school_year: %i[school_id year_id])
    end
  end
end
