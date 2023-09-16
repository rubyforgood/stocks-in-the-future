class CreateStudentAttendances < ActiveRecord::Migration[7.0]
  def change
    create_table :student_attendances do |t|
      t.references :student, null: false, foreign_key: {to_table: :users}
      t.references :school_week, null: false, foreign_key: true
      t.boolean :verified
      t.boolean :attended

      t.timestamps
    end
  end
end
