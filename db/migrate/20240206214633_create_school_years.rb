class CreateSchoolYears < ActiveRecord::Migration[7.1]
  def change
    create_table :school_years do |t|
      t.references :school, null: false, foreign_key: true
      t.references :year, null: false, foreign_key: true

      t.timestamps
    end

    add_index :school_years, [:school_id, :year_id], unique: true
  end
end
