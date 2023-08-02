class CreateSchools < ActiveRecord::Migration[7.0]
  def change
    create_table :schools do |t|
      t.text :name, null: false

      t.timestamps
    end
  end
end
