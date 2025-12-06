class CreateClassroomGrades < ActiveRecord::Migration[8.1]
  def change
    create_table :classroom_grades do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :grade, null: false, foreign_key: true

      t.timestamps
    end

    add_index :classroom_grades, [:classroom_id, :grade_id], unique: true
  end
end
