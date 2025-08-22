start_year = Date.current.year
end_year = start_year + 12

(start_year...end_year).each do |i|
  year = Year.find_or_create_by(name: "#{i} - #{i + 1}")
  year.save!
end
