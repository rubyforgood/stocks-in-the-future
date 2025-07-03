class CreateGradeEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :grade_entries do |t|
      t.references :grade_book, null: false, foreign_key: true
      t.references :user,       null: false, foreign_key: true

      t.string  :math_grade,    null: true
      t.string  :reading_grade, null: true
      t.bigint  :days_missed,   null: false, default: 0

      t.timestamps
    end

    add_index :grade_entries, [:grade_book_id, :user_id], unique: true
  end
end