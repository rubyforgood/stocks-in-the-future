# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :student, class_name: "Student"
  belongs_to :classroom

  validates :student_id, uniqueness: { scope: :classroom_id }
end
