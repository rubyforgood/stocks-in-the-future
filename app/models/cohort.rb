class Cohort < ApplicationRecord
  belongs_to :school
  belongs_to :school_year
  belongs_to :teacher, class_name: "User", foreign_key: "teacher_id"
end
