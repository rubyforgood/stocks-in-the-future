class CreateSchoolPeriods < ActiveRecord::Migration[7.0]
  def change
    create_table :school_periods, force: :cascade do |t|
      t.integer :period_number
      t.integer :cohort_id, null: false
      t.integer :school_id, null: false

      t.timestamps
    end
  end
end
