class AddNotNullConstraintToYearOnYears < ActiveRecord::Migration[7.1]
  def change
    change_column_null :years, :year, false
  end
end
