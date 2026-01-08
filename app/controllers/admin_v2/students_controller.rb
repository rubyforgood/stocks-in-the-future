# frozen_string_literal: true

module AdminV2
  # rubocop:disable Metrics/ClassLength
  class StudentsController < BaseController
    include SoftDeletableFiltering

    before_action :set_student, only: %i[show edit update destroy add_transaction]
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

    def add_transaction
      errors = validate_transaction_params

      if errors.present?
        redirect_to edit_admin_v2_student_path(@student), alert: errors.join(", ")
      else
        transaction = PortfolioTransaction.new(
          portfolio: @student.portfolio,
          amount_cents: transaction_amount_cents,
          transaction_type: transaction_type,
          reason: transaction_reason,
          description: transaction_description
        )

        if transaction.save
          redirect_to admin_v2_student_path(@student), notice: t(".notice")
        else
          redirect_to edit_admin_v2_student_path(@student), alert: transaction.errors.full_messages.join(", ")
        end
      end
    end

    def import
      return redirect_with_missing_file_error if params[:csv_file].blank?

      begin
        results = BulkStudentImportService.import_from_csv(params[:csv_file].path)
        redirect_with_import_results(results)
      rescue CSV::MalformedCSVError => e
        redirect_to admin_v2_students_path, alert: "Invalid CSV format: #{e.message}"
      end
    end

    def template
      send_data BulkStudentImportService.generate_csv_template,
                filename: "student_import_template.csv",
                type: "text/csv",
                disposition: "attachment"
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

    def transaction_params
      params.expect(student: %i[add_fund_amount transaction_type transaction_reason transaction_description])
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
      errors << t("admin_v2.students.add_transaction.errors.transaction_type_blank") if transaction_type.blank?
      errors << t("admin_v2.students.add_transaction.errors.amount_blank") if transaction_amount_cents.blank?
      errors << t("admin_v2.students.add_transaction.errors.reason_blank") if transaction_reason.blank?
      errors
    end

    def redirect_with_missing_file_error
      redirect_to admin_v2_students_path, alert: "Please select a CSV file"
    end

    def redirect_with_import_results(results)
      return redirect_with_no_results_error if results.empty?

      created, skipped, failed = partition_results(results)
      success_messages = build_success_messages(created, skipped)

      if failed.any?
        redirect_with_mixed_results(success_messages, failed)
      else
        redirect_to admin_v2_students_path, notice: success_messages.join(". ")
      end
    end

    def redirect_with_no_results_error
      redirect_to admin_v2_students_path, alert: "No students found in CSV file"
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

    def build_skipped_message(skipped)
      "Skipped #{skipped.count} existing usernames"
    end

    def redirect_with_mixed_results(success_messages, failed)
      error_messages = failed.map { |item| "Row #{item.line_number}: #{item.error_message}" }
      alert_message = "#{failed.count} errors occurred: #{error_messages.join(', ')}"

      if success_messages.any?
        redirect_to admin_v2_students_path, notice: success_messages.join(". "), alert: alert_message
      else
        redirect_to admin_v2_students_path, alert: alert_message
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
