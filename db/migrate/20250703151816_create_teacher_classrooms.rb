class CreateTeacherClassrooms < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_classrooms do |t|
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.references :classroom, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :teacher_classrooms, [:teacher_id, :classroom_id], unique: true
  end
end
