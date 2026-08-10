# frozen_string_literal: true

module Admin
  class ClassroomsController < BaseController
    include ClassroomFormFields

    before_action :set_classroom, only: %i[show edit update toggle_archive]
    before_action :classroom_form_data, only: %i[new edit create update]

    def index
      @classrooms = apply_sorting(Classroom.all, default: "name")

      @breadcrumbs = [
        { label: "Classrooms" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Classrooms", path: admin_classrooms_path },
        { label: @classroom.name }
      ]
    end

    def new
      @classroom = Classroom.new

      @breadcrumbs = [
        { label: "Classrooms", path: admin_classrooms_path },
        { label: "New classroom" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Classrooms", path: admin_classrooms_path },
        { label: @classroom.name, path: admin_classroom_path(@classroom) },
        { label: "Edit" }
      ]
    end

    def create
      @classroom = Classroom.new(classroom_attributes)
      assign_school_year_to_classroom

      if @classroom.save
        redirect_to admin_classroom_path(@classroom), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Classrooms", path: admin_classrooms_path },
          { label: "New classroom" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      assign_school_year_to_classroom

      if @classroom.update(classroom_attributes)
        redirect_to admin_classroom_path(@classroom), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Classrooms", path: admin_classrooms_path },
          { label: @classroom.name, path: admin_classroom_path(@classroom) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def toggle_archive
      authorize @classroom, :toggle_archive?
      @classroom.update!(archived: !@classroom.archived)
      flash[:notice] = @classroom.archived? ? "Classroom has been archived." : "Classroom has been activated."
      redirect_to admin_classroom_path(@classroom)
    end

    private

    def set_classroom
      @classroom = Classroom.find(params.expect(:id))
    end

    # Pundit's list, the same one the app half uses. This wrote its own, and it had drifted: it permitted
    # `school_year_id` and never `teacher_ids`, so the admin screens - the half whose whole job is
    # administration - were the half that could not assign a teacher to a classroom.
    def classroom_params
      permitted_attributes(@classroom || Classroom.new)
    end
  end
end
