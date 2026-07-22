class AddCascadeDeleteToQuartersSchoolYear < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_foreign_key :quarters, :school_years
      add_foreign_key :quarters, :school_years, on_delete: :cascade
    end
  end
end
