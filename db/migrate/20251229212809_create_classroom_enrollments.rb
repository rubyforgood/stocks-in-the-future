class CreateClassroomEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :classroom_enrollments do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :classroom, null: false, foreign_key: true
      t.datetime :enrolled_at, null: false
      t.datetime :unenrolled_at
      t.boolean :primary, default: false, null: false

      t.timestamps
    end

    add_index :classroom_enrollments, [:student_id, :classroom_id, :enrolled_at],
              name: "index_enrollments_on_student_classroom_enrolled"
    add_index :classroom_enrollments, [:student_id, :primary],
              where: '"primary" = true',
              name: "index_enrollments_on_student_primary"
  end
end
