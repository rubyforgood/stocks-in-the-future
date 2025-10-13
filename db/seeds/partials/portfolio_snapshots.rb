# frozen_string_literal: true

mike = User.find_by(email: "mike@example.com")

if mike
  portfolio = Portfolio.find_by(user: mike)

  if portfolio
    # Create 6 months of historical snapshots with realistic value progression
    # Starting 5 months ago and ending with current month
    base_value = 150_00 # $150.00 starting value

    snapshots_data = [
      { months_ago: 5, worth_cents: base_value },
      { months_ago: 4, worth_cents: base_value + 50_00 },  # +$50
      { months_ago: 3, worth_cents: base_value + 120_00 }, # +$70
      { months_ago: 2, worth_cents: base_value + 80_00 },  # -$40 (dip)
      { months_ago: 1, worth_cents: base_value + 180_00 }, # +$100 (recovery)
      { months_ago: 0, worth_cents: base_value + 250_00 }  # +$70 (growth)
    ]

    snapshots_data.each do |data|
      snapshot_date = data[:months_ago].months.ago.beginning_of_month.to_date

      PortfolioSnapshot.find_or_create_by!(
        portfolio: portfolio,
        date: snapshot_date
      ) do |snapshot|
        snapshot.worth_cents = data[:worth_cents]
      end
    end

    puts "Seeded #{snapshots_data.length} portfolio snapshots for Mike's portfolio"
    Rails.logger.info "Seeded #{snapshots_data.length} portfolio snapshots for Mike's portfolio"
  else
    puts "Portfolio not found for Mike. Skipping portfolio snapshots seeding."
    Rails.logger.warn "Portfolio not found for Mike. Skipping portfolio snapshots seeding."
  end
else
  puts "Student user 'Mike' not found. Skipping portfolio snapshots seeding."
  Rails.logger.warn "Student user 'Mike' not found. Skipping portfolio snapshots seeding."
end
