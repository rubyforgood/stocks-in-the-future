# frozen_string_literal: true

class Teacher < User
  has_many :teacher_classrooms, dependent: :destroy
  has_many :classrooms, through: :teacher_classrooms

  def classroom_names
    classrooms.map { |c| "#{c.name} (#{c.grade_display})" }.join(", ")
  end
end
