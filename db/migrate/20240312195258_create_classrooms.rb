# frozen_string_literal: true

class CreateClassrooms < ActiveRecord::Migration[7.1]
  def change
    create_table :classrooms do |t|
      t.string :name
      t.references :year, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.string :grade

      t.timestamps
    end
  end
end
