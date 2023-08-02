class CreateCohorts < ActiveRecord::Migration[7.0]
  def change
    create_table :cohorts do |t|
      t.text :name, null: false
      t.references :school, null: false, foreign_key: true
      t.references :academic_year, null: false, foreign_key: true
      t.integer :grade, null: false
      t.references :teacher, null: false, foreign_key: {to_table: :users}
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
