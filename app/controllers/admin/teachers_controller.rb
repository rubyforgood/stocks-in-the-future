# frozen_string_literal: true

module Admin
  class TeachersController < Admin::ApplicationController
    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end

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

    # need to create the new teacher by the admin
    def create
      temp_password = Devise.friendly_token.first(20)
      classroom_id = teacher_params[:classroom_id]
      classroom = Classroom.find_by(id: classroom_id)

      @teacher = Teacher.new(teacher_params.merge(password: temp_password))

      if @teacher.save
        # checking if any classroom_id is provided or not
        if classroom
          @teacher.classrooms << classroom
        else
          flash[:alert] = t("teachers.create.alert.no_classroom", id: classroom_id)
        end

        @teacher.send_reset_password_instructions
        redirect_to admin_teachers_path, notice: t("teachers.create.notice")
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def teacher_params
      params.expect(teacher: %i[email username classroom_id])
    end

    # See https://administrate-demo.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
