class RemoveCurrentPositionFromPortfolios < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :portfolios, :current_position, :float }
  end
end
