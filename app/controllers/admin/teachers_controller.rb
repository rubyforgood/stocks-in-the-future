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
      # The record's page renders the form, so it needs what the form needs. `edit` was the only action that
      # called this; merging the two pages means `show` does too.
      set_form_data

      @breadcrumbs = [
        { label: "Teachers", path: admin_teachers_path },
        { label: @teacher.display_name.presence || @teacher.username }
      ]
    end

    def new
      @teacher = Teacher.new
      set_form_data

      @breadcrumbs = [
        { label: "Teachers", path: admin_teachers_path },
        { label: "New teacher" }
      ]
    end

    def edit
      set_form_data
      @breadcrumbs = [
        { label: "Teachers", path: admin_teachers_path },
        { label: @teacher.display_name.presence || @teacher.username, path: admin_teacher_path(@teacher) },
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
          { label: "New teacher" }
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
          { label: @teacher.display_name.presence || @teacher.username, path: admin_teacher_path(@teacher) },
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
      params.expect(teacher: [:email, :name, { classroom_ids: [] }])
    end

    # **A teacher's own classrooms are always in the list, whatever the filter says.**
    #
    # Nothing stops a teacher holding classrooms in more than one school - `teacher_classrooms` has no school
    # constraint - but this form used to guarantee they could not. The list was narrowed to one school, the
    # checkbox group is the whole of `classroom_ids`, and `update` assigns what was submitted: so a teacher
    # with a classroom in each of two schools lost one the moment the form was saved. Measured in a console -
    # "A room, B room" in, "A room" out - and it needed no interaction at all, because the filter defaults to
    # the school of their *first* classroom, so opening the page and pressing Update was enough.
    #
    # Unioning their current classrooms into the scope fixes it at the source: whatever the filter shows, the
    # boxes that are already ticked are rendered, so they are still there to be submitted.
    # Every active classroom in the current school year, in school order.
    #
    # **The school filter is gone**, and with it `@schools`, `@selected_school_id` and the union that made
    # the filter safe. It defaulted to the school of the teacher's *first* classroom, so it narrowed the
    # list without anyone choosing anything - which is how it came to drop the second school's classroom on
    # save, and why the list had to be unioned back together afterwards. Nothing is hidden now, so there is
    # nothing to put back.
    #
    # Ordered by school then name, because the row shows both - see `classroom_option_label`.
    def set_form_data
      active_years = Year.current_school_year(Date.current)

      @classrooms = Classroom.active
        .joins(school_year: :school)
        .where(school_years: { year_id: active_years.ids })
        .order("schools.name", :name)
    end
  end
end
