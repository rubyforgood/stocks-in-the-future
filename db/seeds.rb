
# Do not add any seed command to this file. Instead, go to /db/seeds/ where you
# will find:
# - development.rb
# - production.rb
#
# Add your seed code into one of those depending on the environment where you wish
# for it to execute.
#
# The intent is to keep seeds separated by environment to avoid any accidental
# execution of code in Production that was meant for Development.
#
# In addition, seeds are split into multiple files (partials) to keep things
# organised. For more information, see the docoumentation at: docs/seeds.md

puts "Starting database seed."
puts "Current environment is: #{Rails.env.downcase}"
load(Rails.root.join('db', 'seeds', "#{Rails.env.downcase}.rb"))
