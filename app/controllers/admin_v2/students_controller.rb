# frozen_string_literal: true

module AdminV2
  class StudentsController < BaseController
    include SoftDeletableFiltering

    before_action :set_student, only: %i[show edit update destroy]
    before_action :set_discarded_student, only: %i[restore]

    def index
      @students = apply_sorting(scoped_by_discard_status(Student), default: "username")

      @breadcrumbs = [
        { label: "Students" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Students", path: admin_v2_students_path },
        { label: @student.username }
      ]
    end

    def new
      @student = Student.new

      @breadcrumbs = [
        { label: "Students", path: admin_v2_students_path },
        { label: "New Student" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Students", path: admin_v2_students_path },
        { label: @student.username, path: admin_v2_student_path(@student) },
        { label: "Edit" }
      ]
    end

    def create
      @student = Student.new(student_params)

      # Generate a memorable password if not provided
      if @student.password.blank?
        generated_password = MemorablePasswordGenerator.generate
        @student.password = generated_password
        @student.password_confirmation = generated_password
      else
        generated_password = @student.password
      end

      if @student.save
        redirect_to admin_v2_student_path(@student),
                    notice: t(".notice", username: @student.username, password: generated_password)
      else
        @breadcrumbs = [
          { label: "Students", path: admin_v2_students_path },
          { label: "New Student" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @student.update(student_params)
        redirect_to admin_v2_student_path(@student), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Students", path: admin_v2_students_path },
          { label: @student.username, path: admin_v2_student_path(@student) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      username = @student.username
      @student.discard
      redirect_to admin_v2_students_path, notice: t(".notice", username: username)
    end

    def restore
      username = @student.username
      @student.undiscard
      redirect_to admin_v2_students_path(discarded: true), notice: t(".notice", username: username)
    end

    private

    def set_discarded_student
      @student = Student.with_discarded.find(params.expect(:id))
    end

    def set_student
      @student = Student.find(params.expect(:id))
    end

    def student_params
      params.expect(student: %i[username classroom_id password password_confirmation])
    end
  end
end
