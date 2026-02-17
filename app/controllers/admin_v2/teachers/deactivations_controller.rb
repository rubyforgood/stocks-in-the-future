# frozen_string_literal: true

module AdminV2
  module Teachers
    class DeactivationsController < BaseController
      before_action :set_teacher

      def create
        username = @teacher.username
        @teacher.discard
        redirect_back_or_to admin_v2_teachers_path, notice: t(".notice", username: username)
      end

      private

      def set_teacher
        @teacher = Teacher.find(params.expect(:teacher_id))
      end
    end
  end
end
