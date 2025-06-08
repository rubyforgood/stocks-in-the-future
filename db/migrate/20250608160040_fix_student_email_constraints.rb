class FixStudentEmailConstraints < ActiveRecord::Migration[8.0]
  def up
    # Remove the existing unique index on email
    remove_index :users, :email if index_exists?(:users, :email)
    
    # Change email column to allow null and remove default empty string
    change_column :users, :email, :string, null: true, default: nil
    
    # Update existing empty string emails to null for students
    User.where(email: '', type: 'Student').update_all(email: nil)
    
    # Create a partial unique index that only applies to non-null, non-empty emails
    add_index :users, :email, unique: true, where: "email IS NOT NULL AND email != ''"
  end

  def down
    # Remove the partial unique index
    remove_index :users, :email if index_exists?(:users, :email)
    
    # Restore the original email column settings
    change_column :users, :email, :string, null: false, default: ""
    
    # Update null emails back to empty strings
    User.where(email: nil).update_all(email: '')
    
    # Restore the original unique index
    add_index :users, :email, unique: true
  end
end
