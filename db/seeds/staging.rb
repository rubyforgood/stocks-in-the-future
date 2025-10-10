# Staging environment uses the same seeds as development
puts "Staging environment detected - loading development seeds"
load(Rails.root.join('db', 'seeds', 'development.rb'))