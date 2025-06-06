# Plan to Fix Single Table Inheritance (STI) Implementation

## Current Issue
The application is using Single Table Inheritance (STI) for Student and Teacher models that inherit from User. However, the 'type' field, which is required for STI to work properly, is missing from the users table.

## Steps to Fix

1. **Create a new migration to add the 'type' field to the users table**
   - The migration should add a 'type' column with a default value of 'User'
   - It should also update existing records to have 'type' set to 'User'

2. **Run the migration**
   - Apply the migration to update the database schema

3. **Update the User model**
   - Ensure the User model properly handles STI
   - Add any necessary validations or callbacks

4. **Test the implementation**
   - Verify that Student and Teacher models work correctly with STI
   - Ensure that creating and accessing Student and Teacher records works as expected

## Migration Example

```ruby
class AddTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :type, :string, default: 'User', null: false
    change_column_null :users, :type, false
  end
end
```

## Model Update Example

```ruby
class User < ApplicationRecord
  # Existing code...

  # Add STI validation if needed
  validates :type, inclusion: { in: ['User', 'Student', 'Teacher'] }
end
```

## Testing

1. Create a new Student record and verify the 'type' field is set to 'Student'
2. Create a new Teacher record and verify the 'type' field is set to 'Teacher'
3. Update an existing User record to be a Student and verify the 'type' field is updated