class CreateGradeBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :grade_books do |t|
      t.references :quarter,   null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true

      t.string  :status, null: false, default: 'draft'
      t.timestamps
    end

    add_index :grade_books, [:quarter_id, :classroom_id], unique: true
  end
end