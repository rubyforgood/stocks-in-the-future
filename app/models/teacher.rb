# frozen_string_literal: true

class Teacher < User
  attr_accessor :school_id

  has_many :teacher_classrooms, dependent: :destroy
  has_many :classrooms, through: :teacher_classrooms
end
