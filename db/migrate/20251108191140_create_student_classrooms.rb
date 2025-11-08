class CreateStudentClassrooms < ActiveRecord::Migration[8.0]
  def change
    create_table :student_classrooms do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :classroom, null: false, foreign_key: true
      t.boolean :archived, default: false, null: false

      t.timestamps
    end

    add_index :student_classrooms, [:student_id, :classroom_id], unique: true
  end
end
