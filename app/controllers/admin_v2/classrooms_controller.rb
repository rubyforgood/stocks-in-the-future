# frozen_string_literal: true

module AdminV2
  class ClassroomsController < BaseController
    before_action :set_classroom, only: %i[show edit update destroy toggle_archive]

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

    def toggle_archive
      authorize @classroom, :toggle_archive?
      @classroom.update!(archived: !@classroom.archived)
      flash[:notice] = @classroom.archived? ? "Classroom has been archived." : "Classroom has been activated."
      redirect_to admin_v2_classroom_path(@classroom)
    end

    private

    def set_classroom
      @classroom = Classroom.find(params.expect(:id))
    end

    def classroom_params
      params.expect(classroom: [:name, :trading_enabled, :school_year_id, { grade_ids: [] }])
    end
  end
end
