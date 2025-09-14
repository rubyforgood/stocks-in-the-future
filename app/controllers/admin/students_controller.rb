# frozen_string_literal: true

module Admin
  # rubocop:disable Metrics/ClassLength
  class StudentsController < Admin::ApplicationController
    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.

    def update
      super
    end

    def destroy
      username = requested_resource.username
      requested_resource.discard
      redirect_to admin_students_path, notice: "Discarded #{username}"
    end

    def restore
      student = resource_class.with_discarded.find(params[:id])
      username = student.username
      student.undiscard
      redirect_to admin_students_path(discarded: 1), notice: "Restored #{username}"
    end

    def import
      return redirect_with_missing_file_error if params[:csv_file].blank?

      begin
        results = BulkStudentImportService.import_from_csv(params[:csv_file].path)
        redirect_with_import_results(results)
      rescue CSV::MalformedCSVError => e
        redirect_to admin_students_path, alert: "Invalid CSV format: #{e.message}"
      end
    end

    def add_transaction
      errors = validate_transaction_params
      student = Student.find(params["student_id"])

      if errors.present?
        student.errors.add(:base, errors.join(", "))
        redirect_to edit_admin_student_path(student), alert: errors.join(", ")
      end

      PortfolioTransaction.create!(
        portfolio: student.portfolio,
        amount_cents: fund_amount,
        transaction_type: transaction_type,
        reason: transaction_reason
      )
      redirect_to admin_student_path(student), notice: t("students.add_transaction.success")
    end

    def template
      send_data BulkStudentImportService.generate_csv_template,
                filename: "student_import_template.csv",
                type: "text/csv",
                disposition: "attachment"
    end

    # Override this method to specify custom lookup behavior.
    # This will be used to set the resource for the `show`, `edit`, and `update`
    # actions.
    #
    # def find_resource(param)
    #   Foo.find_by!(slug: param)
    # end

    # The result of this lookup will be available as `requested_resource`

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    #
    def scoped_resource
      scope = resource_class
      if params[:discarded] == "1"
        scope.discarded
      elsif params[:all] == "1"
        scope.with_discarded
      else
        scope.kept
      end
    end

    # def scoped_resource
    #   if current_user.super_admin?
    #     resource_class
    #   else
    #     resource_class.with_less_stuff
    #   end
    # end

    # Override `resource_params` if you want to transform the submitted
    # data before it's persisted. For example, the following would turn all
    # empty values into nil values. It uses other APIs such as `resource_class`
    # and `dashboard`:
    #
    # def resource_params
    #   params.require(resource_class.model_name.param_key).
    #     permit(dashboard.permitted_attributes(action_name)).
    #     transform_values { |value| value == "" ? nil : value }
    # end

    # See https://administrate-demo.herokuapp.com/customizing_controller_actions
    # for more information
    #
    private

    def redirect_with_missing_file_error
      redirect_to admin_students_path, alert: "Please select a CSV file" # rubocop:disable Rails/I18nLocaleTexts
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
      redirect_to admin_students_path, alert: "No students found in CSV file" # rubocop:disable Rails/I18nLocaleTexts
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
        redirect_to admin_students_path, notice: success_messages.join(". "), alert: alert_message
      else
        redirect_to admin_students_path, alert: alert_message
      end
    end

    def fund_amount
      @fund_amount ||= params["student"]["add_fund_amount"]
    end

    def transaction_type
      @transaction_type ||= params["student"]["transaction_type"]
    end

    def transaction_reason
      @transaction_reason ||= params["student"]["transaction_reason"]
    end

    def validate_transaction_params
      errors = []
      errors << "Transaction Type must be present" if transaction_type.blank?
      errors << "Amount must be present" if fund_amount.blank?
      errors << "Reason must be present" if transaction_reason.blank?
      errors
    end
  end
  # rubocop:enable Metrics/ClassLength
end
