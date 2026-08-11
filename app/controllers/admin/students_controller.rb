# frozen_string_literal: true

module Admin
  # rubocop:disable Metrics/ClassLength
  class StudentsController < BaseController
    include SoftDeletableFiltering

    # How many distinct skip reasons the import flash names before it summarises the rest.
    SKIP_REASONS_SHOWN = 3

    before_action :set_student, only: %i[show edit update destroy add_transaction]
    before_action :set_discarded_student, only: %i[restore]

    def index
      @students = apply_sorting(scoped_by_discard_status(Student), default: "username")

      @breadcrumbs = [
        { label: "Students" }
      ]
    end

    def show
      load_record_page
    end

    def new
      @student = Student.new

      @breadcrumbs = [
        { label: "Students", path: admin_students_path },
        { label: "New student" }
      ]
    end

    # PREVIEW: the record page edits in place, so `edit` renders it - which means it needs everything that
    # page reads. Every path that renders the record page has to load the same data, and there are three:
    # show, edit, and a failed update. Missing one is a NoMethodError on nil, which is how the other eight
    # conversions found this twice.
    def edit
      load_record_page
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

      if @student.save(context: :student_form)
        redirect_to admin_student_path(@student),
                    notice: t(".notice", username: @student.username, password: generated_password)
      else
        @breadcrumbs = [
          { label: "Students", path: admin_students_path },
          { label: "New student" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      @student.assign_attributes(student_params)

      if @student.save(context: :student_form)
        redirect_to admin_student_path(@student), notice: t(".notice")
      else
        load_record_page
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      username = @student.username
      @student.discard
      redirect_to admin_students_path, notice: t(".notice", username: username)
    end

    def restore
      username = @student.username
      @student.undiscard
      redirect_to admin_students_path(discarded: true), notice: t(".notice", username: username)
    end

    def add_transaction
      errors = validate_transaction_params

      if errors.present?
        redirect_to edit_admin_student_path(@student), alert: errors.join(", ")
      else
        transaction = PortfolioTransaction.new(
          portfolio: @student.portfolio,
          amount_cents: transaction_amount_cents,
          transaction_type: transaction_type,
          reason: transaction_reason,
          description: transaction_description
        )

        if transaction.save
          redirect_to admin_student_path(@student), notice: t(".notice")
        else
          redirect_to edit_admin_student_path(@student), alert: transaction.errors.full_messages.join(", ")
        end
      end
    end

    def import
      return redirect_with_missing_file_error if params[:csv_file].blank?

      begin
        results = BulkStudentImportService.import_from_csv(params.expect(:csv_file).path)
        redirect_with_import_results(results)
      rescue CSV::MalformedCSVError => e
        redirect_to admin_students_path, alert: "Invalid CSV format: #{e.message}"
      end
    end

    def template
      send_data BulkStudentImportService.generate_csv_template,
                filename: "student_import_template.csv",
                type: "text/csv",
                disposition: "attachment"
    end

    private

    # Everything the record page renders, in one place: the two collections, the earnings summary, and the
    # trail. `@transactions` is loaded here rather than queried in the template because both the section's
    # count and the table read it - a derived figure and the thing it derives from must come from one query.
    def load_record_page
      @attendance_entries = AttendanceEntryPresenter.for_student(@student)

      if @student.portfolio.present?
        @earnings_summary = EarningsSummary.new(@student.portfolio)
        @transactions = @student.portfolio.portfolio_transactions.order(created_at: :desc)
      end

      @breadcrumbs = [
        { label: "Students", path: admin_students_path },
        { label: @student.display_name }
      ]
    end

    def set_discarded_student
      @student = Student.with_discarded.find(params.expect(:id))
    end

    def set_student
      @student = Student.find(params.expect(:id))
    end

    def student_params
      params.expect(student: %i[name username classroom_id password password_confirmation])
    end

    def transaction_params
      params.permit(:add_fund_amount, :transaction_type, :transaction_reason, :transaction_description)
    end

    def transaction_amount_cents
      amount = transaction_params[:add_fund_amount]
      amount.present? ? (amount.to_f * 100).to_i : nil
    end

    def transaction_type
      transaction_params[:transaction_type]
    end

    def transaction_reason
      transaction_params[:transaction_reason]
    end

    def transaction_description
      transaction_params[:transaction_description]
    end

    def validate_transaction_params
      errors = []
      errors << t("admin.students.add_transaction.errors.transaction_type_blank") if transaction_type.blank?
      errors << t("admin.students.add_transaction.errors.amount_blank") if transaction_amount_cents.blank?
      errors << t("admin.students.add_transaction.errors.reason_blank") if transaction_reason.blank?
      errors
    end

    def redirect_with_missing_file_error
      redirect_to admin_students_path, alert: t(".errors.no_file")
    end

    def redirect_with_import_results(results)
      return redirect_with_no_results_error if results.empty?

      created, skipped, failed = partition_results(results)
      success_messages = build_success_messages(created, skipped)

      if failed.any?
        redirect_with_mixed_results(success_messages, failed)
      else
        redirect_to admin_students_path, notice: success_messages.join(". ")
      end
    end

    def redirect_with_no_results_error
      redirect_to admin_students_path, alert: t(".errors.no_students")
    end

    def partition_results(results)
      [
        results.select(&:created?),
        results.select(&:skipped?),
        results.select(&:failed?)
      ]
    end

    def build_success_messages(created, skipped)
      messages = []
      messages << build_created_message(created) if created.any?
      messages << build_skipped_message(skipped) if skipped.any?
      messages
    end

    def build_created_message(created)
      usernames = created.map { |item| item.student.username }
      "Successfully created #{created.count} students: #{usernames.join(', ')}"
    end

    # Derived from the reasons the rows were actually skipped, not from an assumption about what a skip
    # means. It said "Skipped N existing usernames", which was true while a duplicate was the only thing
    # that produced a skip and became a lie the moment anything else did - a nameless row briefly landed
    # here and was reported as a duplicate. Now the wording cannot drift from the cause: a new skip reason
    # describes itself, and the bucket carries no meaning of its own.
    def build_skipped_message(skipped)
      reasons = skipped.map { |item| item.result.error_message }.uniq
      shown = reasons.first(SKIP_REASONS_SHOWN)
      shown << "and #{reasons.size - SKIP_REASONS_SHOWN} more" if reasons.size > SKIP_REASONS_SHOWN

      "Skipped #{skipped.count} #{'row'.pluralize(skipped.count)}: #{shown.to_sentence}"
    end

    def redirect_with_mixed_results(success_messages, failed)
      error_messages = failed.map { |item| "Row #{item.line_number}: #{item.error_message}" }
      alert_message = "#{failed.count} errors occurred: #{error_messages.join(', ')}"

      if success_messages.any?
        redirect_to admin_students_path, notice: success_messages.join(". "), alert: alert_message
      else
        redirect_to admin_students_path, alert: alert_message
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
