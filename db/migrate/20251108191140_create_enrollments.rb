class CreateEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :enrollments do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :classroom, null: false, foreign_key: true
      t.boolean :archived, default: false, null: false

      t.timestamps
    end

    add_index :enrollments, [:student_id, :classroom_id], unique: true
  end
end
