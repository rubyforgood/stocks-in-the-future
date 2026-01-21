# frozen_string_literal: true

module AdminV2
  class TeachersController < BaseController
    before_action :set_teacher, only: %i[show edit update destroy]

    def index
      @teachers = apply_sorting(Teacher.all, default: "username")

      @breadcrumbs = [
        { label: "Teachers" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Teachers", path: admin_v2_teachers_path },
        { label: @teacher.username }
      ]
    end

    def new
      @teacher = Teacher.new

      @breadcrumbs = [
        { label: "Teachers", path: admin_v2_teachers_path },
        { label: "New Teacher" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Teachers", path: admin_v2_teachers_path },
        { label: @teacher.username, path: admin_v2_teacher_path(@teacher) },
        { label: "Edit" }
      ]
    end

    def create
      temp_password = Devise.friendly_token.first(20)
      classroom_ids = teacher_params[:classroom_ids]&.reject(&:blank?)

      @teacher = Teacher.new(teacher_params.except(:classroom_ids).merge(password: temp_password))
      @teacher.classroom_ids = classroom_ids if classroom_ids.present?

      if @teacher.save
        @teacher.send_reset_password_instructions
        redirect_to admin_v2_teacher_path(@teacher), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Teachers", path: admin_v2_teachers_path },
          { label: "New Teacher" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      classroom_ids = teacher_params[:classroom_ids]&.reject(&:blank?)
      update_params = teacher_params.except(:classroom_ids)
      update_params[:classroom_ids] = classroom_ids if classroom_ids.present?

      if @teacher.update(update_params)
        redirect_to admin_v2_teacher_path(@teacher), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Teachers", path: admin_v2_teachers_path },
          { label: @teacher.username, path: admin_v2_teacher_path(@teacher) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      username = @teacher.username
      @teacher.discard
      redirect_to admin_v2_teachers_path, notice: t(".notice", username: username)
    end

    private

    def set_teacher
      @teacher = Teacher.find(params.expect(:id))
    end

    def teacher_params
      params.expect(teacher: [:username, :email, :name, { classroom_ids: [] }])
    end
  end
end
