class CreateClassrooms < ActiveRecord::Migration[7.1]
  def change
    create_table :classrooms do |t|
      t.integer :grade
      t.references :year, null: false, foreign_key: true
      t.string :name
      t.references :school, null: false, foreign_key: true

      t.timestamps
    end
  end
end
