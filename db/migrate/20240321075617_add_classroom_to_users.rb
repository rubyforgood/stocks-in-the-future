class AddClassroomToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :classroom, foreign_key: true
  end
end
