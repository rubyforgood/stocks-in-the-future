# frozen_string_literal: true

module AdminV2
  class GradesController < BaseController
    before_action :set_grade, only: %i[show edit update destroy]

    def index
      @grades = apply_sorting(Grade.all, default: "level")

      @breadcrumbs = [
        { label: "Grades" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Grades", path: admin_v2_grades_path },
        { label: @grade.name }
      ]
    end

    def new
      @grade = Grade.new
      @breadcrumbs = [
        { label: "Grades", path: admin_v2_grades_path },
        { label: "New Grade" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Grades", path: admin_v2_grades_path },
        { label: @grade.name, path: admin_v2_grade_path(@grade) },
        { label: "Edit" }
      ]
    end

    def create
      @grade = Grade.new(grade_params)

      if @grade.save
        redirect_to admin_v2_grade_path(@grade), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Grades", path: admin_v2_grades_path },
          { label: "New Grade" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @grade.update(grade_params)
        redirect_to admin_v2_grade_path(@grade), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Grades", path: admin_v2_grades_path },
          { label: @grade.name, path: admin_v2_grade_path(@grade) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @grade.destroy
      redirect_to admin_v2_grades_path, notice: t(".notice")
    end

    private

    def set_grade
      @grade = Grade.find(params[:id])
    end

    def grade_params
      params.expect(grade: %i[level name])
    end
  end
end
