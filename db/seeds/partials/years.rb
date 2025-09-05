current_year = Date.current.year
start_year = current_year - 3
end_year = current_year + 10

(start_year..end_year).each do |i|
  year = Year.find_or_create_by(name: "#{i} - #{i + 1}")
  year.save!
end
