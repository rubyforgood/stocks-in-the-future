# frozen_string_literal: true

module AdminV2
  module FormHelper
    # Creates a form using the AdminV2::FormBuilder
    # Usage: admin_form_for @resource do |f|
    #          f.text_field :name
    #          f.email_field :email
    #          f.submit_button
    #        end
    def admin_form_for(record, options = {}, &)
      options[:builder] = AdminV2::FormBuilder
      options[:html] ||= {}
      options[:html][:class] = "space-y-6 #{options[:html][:class]}"

      form_with(model: record, scope: model_scope(record), url: form_url(record), **options, &)
    end

    private

    # Determines the model scope for the form (e.g., :admin_v2_announcement)
    def model_scope(record)
      return record.first.model_name.param_key if record.is_a?(Array)

      record.model_name.param_key
    end

    # Determines the form URL based on the record (handles both new and existing records)
    def form_url(record)
      if record.is_a?(Array)
        resource = record.last
        if resource.persisted?
          [:admin_v2, resource]
        else
          record.first.is_a?(Symbol) ? [record.first, :admin_v2, resource] : [:admin_v2, resource]
        end
      else
        resource = record
        resource.persisted? ? [:admin_v2, resource] : [:admin_v2, resource.class.model_name.collection]
      end
    end
  end
end
