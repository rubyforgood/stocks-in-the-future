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
        { label: "New School" }
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
      year_ids = school_params[:year_ids]&.reject(&:blank?)
      @school = School.new(school_params.except(:year_ids))
      @school.year_ids = year_ids if year_ids.present?

      if @school.save
        redirect_to admin_school_path(@school), notice: t(".notice")
      else
        set_form_data
        @breadcrumbs = [
          { label: "Schools", path: admin_schools_path },
          { label: "New School" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      year_ids = school_params[:year_ids]&.reject(&:blank?)
      update_params = school_params.except(:year_ids)
      update_params[:year_ids] = year_ids || []

      if @school.update(update_params)
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
      @school = School.find(params[:id])
    end

    def set_form_data
      @years = Year.ordered_by_start_year
    end

    def school_params
      params.expect(school: [:name, { year_ids: [] }])
    end
  end
end
