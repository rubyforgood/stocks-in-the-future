class UpdateUserModel < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :first_name, :string, limit: 50
    add_column :users, :last_name, :string, limit: 50
    add_column :users, :username, :string, limit: 50
    add_column :users, :active, :boolean, default: true, null: false
  end
end
