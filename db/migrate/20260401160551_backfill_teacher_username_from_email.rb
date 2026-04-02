class BackfillTeacherUsernameFromEmail < ActiveRecord::Migration[8.1]
  def up
    User.where(type: "Teacher").find_each do |teacher|
      teacher.update_column(:username, teacher.email) if teacher.email.present?
    end
  end

  def down
    # No safe way to reverse — username values before migration are unknown
  end
end
