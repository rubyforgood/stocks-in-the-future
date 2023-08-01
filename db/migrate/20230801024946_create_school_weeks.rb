class CreateSchoolWeeks < ActiveRecord::Migration[7.0]
  def change
    create_table :school_weeks do |t|
      t.integer :week_number, default: 0
      t.integer :cohort_id
      t.integer :week_id

      t.timestamps
    end
  end
end
