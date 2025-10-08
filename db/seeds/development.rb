# Add the seed actions for the development environment to this file.

puts "Development seed running."
start_time = Time.now
puts ""

# ---------------------- Add your seed code in this block ----------------------

# The order of these seed files can be important due to model dependencies.

# Create years
puts "Creating years..."
load(Rails.root.join("db", "seeds", "partials", "years.rb"))
puts "...done."

# Create schools
puts "Creating schools..."
load(Rails.root.join("db", "seeds", "partials", "schools.rb"))
puts "...done."

# Create school years
puts "Creating school years..."
load(Rails.root.join("db", "seeds", "partials", "school_years.rb"))
puts "...done."

# Create quarters
puts "Creating quarters..."
load(Rails.root.join("db", "seeds", "partials", "quarters.rb"))
puts "...done."

# Create classrooms
puts "Creating classrooms..."
load(Rails.root.join("db", "seeds", "partials", "classrooms.rb"))
puts "...done."

# Create users
puts "Creating users..."
load(Rails.root.join("db", "seeds", "partials", "users.rb"))
puts "...done."

# Create stocks
puts "Creating stocks..."
load(Rails.root.join("db", "seeds", "partials", "stocks.rb"))
puts "...done."

# Create portfolio transactions
puts "Creating portfolio transactions..."
load(Rails.root.join("db", "seeds", "partials", "portfolio_transactions.rb"))
puts "...done."

# Create grade books and grade entries
puts "Creating grade books and entries..."
load(Rails.root.join("db", "seeds", "partials", "grade_books_entries.rb"))
puts "...done."

# Create orders
puts "Creating orders..."
load(Rails.root.join("db", "seeds", "partials", "orders.rb"))
puts "...done."

# Create portfolio snapshots
puts "Creating portfolio snapshots..."
load(Rails.root.join("db", "seeds", "partials", "portfolio_snapshots.rb"))
puts "...done."

# ------------------------------------------------------------------------------

end_time = Time.now
run_time = end_time - start_time
puts "Development seed completed in #{run_time} seconds."
