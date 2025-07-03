class CreateQuarters < ActiveRecord::Migration[8.0]
  def change
    create_table :quarters do |t|
      t.string :name
      t.references :school_year, null: false, foreign_key: true

      t.timestamps
    end
  end
end
