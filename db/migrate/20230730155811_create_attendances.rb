class CreateAttendances < ActiveRecord::Migration[7.0]
  def change
    create_table :attendances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :school_week, null: false, foreign_key: true
      t.integer :school_period_id
      t.boolean :verified, default: false, null: false
      t.boolean :attended, default: false, null: false
      t.integer :quarter_bonus, limit: 1

      t.timestamps
    end
  end
end
