class AddNumberToQuarters < ActiveRecord::Migration[8.0]
  def change
    add_column :quarters, :number, :integer, null: false
  end
end
