class AddAcademicYearToSchools < ActiveRecord::Migration[7.0]
  def change
    add_reference :schools, :academic_year, null: false, foreign_key: true
  end
end
