class CreateGrades < ActiveRecord::Migration[8.1]
  def change
    create_table :grades do |t|
      t.string :name, null: false
      t.integer :level, null: false
      t.timestamps
    end

    add_index :grades, :level, unique: true
    add_index :grades, :name, unique: true

    reversible do |dir|
      dir.up do
        grades = [
          { name: "Kindergarten", level: 0 },
          { name: "1st Grade",    level: 1 },
          { name: "2nd Grade",    level: 2 },
          { name: "3rd Grade",    level: 3 },
          { name: "4th Grade",    level: 4 },
          { name: "5th Grade",    level: 5 },
          { name: "6th Grade",    level: 6 },
          { name: "7th Grade",    level: 7 },
          { name: "8th Grade",    level: 8 },
          { name: "9th Grade",    level: 9 },
          { name: "10th Grade",   level: 10 },
          { name: "11th Grade",   level: 11 },
          { name: "12th Grade",   level: 12 },
        ]

        Grade.upsert_all(
          grades,
          unique_by: :level
        )
      end
    end
  end
end
