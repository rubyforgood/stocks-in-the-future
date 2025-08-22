# Create 4 quarters for the first school year
school_year = SchoolYear.find_by(school: School.first, year: Year.first)

if school_year
  (1..4).each do |n|
    Quarter.find_or_create_by!(
      school_year: school_year,
      number: n
    ) do |q|
      q.update(name: "Quarter #{n}")
    end
  end
  puts "Quarters created for school year: #{school_year.year.name} at #{school_year.school.name}."
  Rails.logger.info "Created 4 quarters for school year: #{school_year.year.name} at #{school_year.school.name}."
else
  puts "No current school year found. Skipping quarter creation."
end
