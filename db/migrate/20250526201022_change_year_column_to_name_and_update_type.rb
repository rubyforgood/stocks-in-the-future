# frozen_string_literal: true

class ChangeYearColumnToNameAndUpdateType < ActiveRecord::Migration[7.2]
  def up
    rename_column :years, :year, :name
    change_column :years, :name, :string, null: false
  end

  def down
    change_column :years, :name, :integer
    rename_column :years, :name, :year
  end
end
