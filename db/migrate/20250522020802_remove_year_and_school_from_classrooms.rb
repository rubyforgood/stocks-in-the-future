class RemoveYearAndSchoolFromClassrooms < ActiveRecord::Migration[7.2]
  def change
    remove_reference :classrooms, :year, foreign_key: true
    remove_reference :classrooms, :school, foreign_key: true
  end
end
