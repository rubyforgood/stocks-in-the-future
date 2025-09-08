class AddGradeNumericToClassrooms < ActiveRecord::Migration[8.0]
  def change
    add_column :classrooms, :grade_numeric, :integer
  end
end
