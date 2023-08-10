class CreateStudentAttendences < ActiveRecord::Migration[7.0]
  def change
    create_table :student_attendences do |t|
      t.references :user, null: false, foreign_key: true
      t.references :school_week, null: false, foreign_key: true
      t.boolean :verified
      t.boolean :attended

      t.timestamps
    end
  end
end
