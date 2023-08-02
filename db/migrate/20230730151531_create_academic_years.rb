class CreateAcademicYears < ActiveRecord::Migration[7.0]
  def change
    create_table :academic_years do |t|
      t.text :year_name, null: false

      t.timestamps
    end
  end
end
