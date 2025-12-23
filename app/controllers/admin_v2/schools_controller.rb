# frozen_string_literal: true

module AdminV2
  class SchoolsController < BaseController
    before_action :set_school, only: %i[show edit update destroy]

    def index
      @schools = School.order(:name)

      # Apply sorting if params present
      if params[:sort].present?
        direction = params[:direction] == "desc" ? :desc : :asc
        @schools = @schools.order(params[:sort] => direction)
      end

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
      @school = School.new(school_params)

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
      if @school.update(school_params)
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
      params.expect(school: [:name])
    end
  end
end
