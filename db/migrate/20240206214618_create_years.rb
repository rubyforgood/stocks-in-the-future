class CreateYears < ActiveRecord::Migration[7.1]
  def change
    create_table :years do |t|
      t.integer :year

      t.timestamps
    end

    add_index :years, :year, unique: true
  end
end
