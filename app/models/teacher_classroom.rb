# frozen_string_literal: true

class TeacherClassroom < ApplicationRecord
  belongs_to :teacher, class_name: "Teacher"
  belongs_to :classroom

  validates :teacher_id, uniqueness: { scope: :classroom_id }
end
