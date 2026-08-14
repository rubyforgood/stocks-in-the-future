# frozen_string_literal: true

module Admin
  class ClassroomsController < BaseController
    include ClassroomFormFields
    include SoftDeletableFiltering

    before_action :set_classroom, only: %i[show edit update toggle_archive]
    # `show` is on this list now: the record's page renders the form, so it needs the form's collections. And
    # the roster comes with it, because `edit` and a failed `update` render the same page - the first version
    # loaded it in `show` alone and both of those blew up on `nil.any?`.
    before_action :classroom_form_data, only: %i[show new edit create update]
    before_action :load_roster, only: %i[show edit update]

    def index
      @classrooms = apply_sorting(filtered_classrooms, default: "name")

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
      @classroom = Classroom.new(classroom_params)

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
      if @classroom.update(classroom_params)
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
      # "restored", pairing with "archived" - the button says Restore.
      flash[:notice] = @classroom.archived? ? "Classroom has been archived." : "Classroom has been restored."

      # Back where the action was taken, not off to the record's page. Archiving is a *list* action here -
      # it is a row action on the index - and every other row action in this half already returns to its
      # list. Gmail, GitHub, Linear, Stripe and Polaris all keep you in place and report what happened in
      # a message; being moved to a page you did not ask for is the cost of one click on a row.
      #
      # `redirect_back_or_to` rather than the index path outright, because the same action is offered on the
      # classroom's own page through `archive_button`, and from there the right destination is that page,
      # showing its new state.
      redirect_back_or_to(admin_classrooms_path)
    end

    private

    # `Classroom` archives with a boolean column rather than `discard`, so it cannot use the concern's
    # `scoped_by_discard_status` - but it can and does share the tabs and their query params.
    #
    # The default is Active, which is a change: this index listed archived classrooms among the live ones and
    # the Status column was the only thing telling them apart. Sorting by Archived used to group them, and it
    # went when two badge columns became one, which left no way to see them together at all.
    def filtered_classrooms
      case discard_filter
      when :discarded then Classroom.archived
      when :all       then Classroom.all
      else                 Classroom.active
      end
    end

    # Loaded here rather than queried from the view, with the limit explicit so the page can say it truncated
    # rather than presenting ten students as the whole roster.
    def load_roster
      @students = @classroom.students.limit(10).to_a
    end

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
