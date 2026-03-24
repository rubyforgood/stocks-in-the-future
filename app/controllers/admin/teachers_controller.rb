# frozen_string_literal: true

module Admin
  class TeachersController < BaseController
    include SoftDeletableFiltering

    before_action :set_teacher, only: %i[show edit update destroy]
    before_action :require_deactivated, only: %i[destroy]

    def index
      @teachers = apply_sorting(scoped_by_discard_status(Teacher), default: "username")

      @breadcrumbs = [
        { label: "Teachers" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Teachers", path: admin_teachers_path },
        { label: @teacher.username }
      ]
    end

    def new
      @teacher = Teacher.new
      set_form_data

      @breadcrumbs = [
        { label: "Teachers", path: admin_teachers_path },
        { label: "New Teacher" }
      ]
    end

    def edit
      set_form_data
      @breadcrumbs = [
        { label: "Teachers", path: admin_teachers_path },
        { label: @teacher.username, path: admin_teacher_path(@teacher) },
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
        redirect_to admin_teacher_path(@teacher), notice: t(".notice")
      else
        set_form_data
        @breadcrumbs = [
          { label: "Teachers", path: admin_teachers_path },
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
        redirect_to admin_teacher_path(@teacher), notice: t(".notice")
      else
        set_form_data
        @breadcrumbs = [
          { label: "Teachers", path: admin_teachers_path },
          { label: @teacher.username, path: admin_teacher_path(@teacher) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      username = @teacher.username
      @teacher.really_destroy!
      redirect_to admin_teachers_path, notice: t(".notice", username: username)
    end

    private

    def set_teacher
      @teacher = Teacher.find(params.expect(:id))
    end

    def require_deactivated
      return if @teacher.discarded?

      redirect_to edit_admin_teacher_path(@teacher), alert: t("admin.teachers.destroy.must_be_deactivated")
    end

    def teacher_params
      params.expect(teacher: [:email, :name, :username, { classroom_ids: [] }])
    end

    def set_form_data
      active_years = Year.current_school_year(Date.current)
      @schools = School.joins(:school_years).where(school_years: { year_id: active_years.ids }).distinct.order(:name)

      @selected_school_id = params[:school_id] || @teacher.classrooms.first&.school&.id

      @classrooms = Classroom.active.joins(:school_year).where(school_years: { year_id: active_years.ids })
      @classrooms = @classrooms.where(school_years: { school_id: @selected_school_id }) if @selected_school_id.present?
      @classrooms = @classrooms.order(:name)
    end
  end
end
