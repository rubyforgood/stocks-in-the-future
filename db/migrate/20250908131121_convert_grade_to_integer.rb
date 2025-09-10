class ConvertGradeToInteger < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :classrooms, :grade, :string }
    add_column :classrooms, :grade, :integer
  end
end
