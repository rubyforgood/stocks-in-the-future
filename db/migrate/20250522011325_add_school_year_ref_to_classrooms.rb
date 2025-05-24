class AddSchoolYearRefToClassrooms < ActiveRecord::Migration[7.2]
  def change
    add_reference :classrooms, :school_year, foreign_key: true
  end
end
