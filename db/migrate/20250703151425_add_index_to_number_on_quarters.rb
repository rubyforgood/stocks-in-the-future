class AddIndexToNumberOnQuarters < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :quarters, [:school_year_id, :number], unique: true, algorithm: :concurrently
  end
end
