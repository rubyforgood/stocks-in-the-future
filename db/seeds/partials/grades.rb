# Create grade levels 5-8 
Classroom::GRADE_RANGE.each do |level|
  # Create the grade name with proper ordinal (5th, 6th, 7th, etc.)
  grade_name = "#{level.ordinalize} Grade"
  
  grade = Grade.find_or_create_by(level: level) do |g|
    g.name = grade_name
  end
  
  # Update name if it's not following the convention
  if grade.persisted? && grade.name != grade_name
    grade.update!(name: grade_name)
  end
end