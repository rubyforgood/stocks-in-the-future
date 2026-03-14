# frozen_string_literal: true

module AdminV2
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
        { label: "Schools", path: admin_v2_schools_path },
        { label: @school.name }
      ]
    end

    def new
      @school = School.new
      @breadcrumbs = [
        { label: "Schools", path: admin_v2_schools_path },
        { label: "New School" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Schools", path: admin_v2_schools_path },
        { label: @school.name, path: admin_v2_school_path(@school) },
        { label: "Edit" }
      ]
    end

    def create
      year_ids = school_params[:year_ids]&.reject(&:blank?)
      @school = School.new(school_params.except(:year_ids))
      @school.year_ids = year_ids if year_ids.present?

      if @school.save
        redirect_to admin_v2_school_path(@school), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Schools", path: admin_v2_schools_path },
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
        redirect_to admin_v2_school_path(@school), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Schools", path: admin_v2_schools_path },
          { label: @school.name, path: admin_v2_school_path(@school) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @school.destroy
      redirect_to admin_v2_schools_path, notice: t(".notice")
    end

    private

    def set_school
      @school = School.find(params[:id])
    end

    def school_params
      params.expect(school: [:name, { year_ids: [] }])
    end
  end
end
