# Add the seed actions for the production environment to this file.

puts "Production seed running."
start_time = Time.now
puts ""

# ---------------------- Add your seed code in this block ----------------------

# Create years
puts "Creating years..."
load(Rails.root.join("db", "seeds", "partials", "years.rb"))
puts "...done."

# Create grades
puts "Creating grades..."
load(Rails.root.join("db", "seeds", "partials", "grades.rb"))
puts "...done."

# Create stocks
puts "Creating stocks..."
load(Rails.root.join("db", "seeds", "partials", "stocks.rb"))
puts "...done."

# ------------------------------------------------------------------------------

end_time = Time.now
run_time = end_time - start_time
puts "Production seed completed in #{run_time} seconds."
