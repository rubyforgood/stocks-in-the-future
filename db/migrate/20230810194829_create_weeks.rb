class CreateWeeks < ActiveRecord::Migration[7.0]
  def change
    create_table :weeks, force: :cascade do |t|
      t.integer :academic_year_id, null: false
      t.date :start_date, null: false

      t.timestamps
    end
  end
end
