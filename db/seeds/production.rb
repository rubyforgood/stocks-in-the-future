# Add the seed actions for the production environment to this file.

puts "Production seed running."
start_time = Time.now
puts ""

# ---------------------- Add your seed code in this block ----------------------

# EXAMPLE: Create a default admin user
# puts "Creating default admin user..."
# load(Rails.root.join("db", "seeds", "partials", "prod_admin_user.rb"))
# puts ""

# ------------------------------------------------------------------------------

end_time = Time.now
run_time = end_time - start_time
puts "Production seed completed in #{run_time} seconds."
