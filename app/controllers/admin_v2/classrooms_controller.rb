# frozen_string_literal: true

module AdminV2
  class ClassroomsController < BaseController
    before_action :set_classroom, only: %i[show edit update destroy]

    def index
      @classrooms = apply_sorting(Classroom.all, default: "name")

      @breadcrumbs = [
        { label: "Classrooms" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Classrooms", path: admin_v2_classrooms_path },
        { label: @classroom.name }
      ]
    end

    def new
      @classroom = Classroom.new

      @breadcrumbs = [
        { label: "Classrooms", path: admin_v2_classrooms_path },
        { label: "New Classroom" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Classrooms", path: admin_v2_classrooms_path },
        { label: @classroom.name, path: admin_v2_classroom_path(@classroom) },
        { label: "Edit" }
      ]
    end

    def create
      @classroom = Classroom.new(classroom_params)

      if @classroom.save
        redirect_to admin_v2_classroom_path(@classroom), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Classrooms", path: admin_v2_classrooms_path },
          { label: "New Classroom" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @classroom.update(classroom_params)
        redirect_to admin_v2_classroom_path(@classroom), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Classrooms", path: admin_v2_classrooms_path },
          { label: @classroom.name, path: admin_v2_classroom_path(@classroom) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @classroom.destroy
      redirect_to admin_v2_classrooms_path, notice: t(".notice")
    end

    private

    def set_classroom
      @classroom = Classroom.find(params.expect(:id))
    end

    def classroom_params
      params.expect(classroom: %i[name grade trading_enabled school_year_id])
    end
  end
end
