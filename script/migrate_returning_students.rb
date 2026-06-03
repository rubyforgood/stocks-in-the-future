#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Layout/LineLength

# Usage: RAILS_ENV=production bin/rails runner script/migrate_returning_students.rb path/to/students.csv --classroom=ID [--dry-run]
#
# CSV must have these named headers (case-sensitive):
#   Username, Current Earnings, Remaining Balance,
#   Under Armour Shares, Under Armour Price, Sony Shares, Sony Price,
#   Gap Shares, Gap Price, Ford Shares, Ford Price,
#   Southwest Shares, Southwest Price, Verizon Shares, Verizon Price,
#   Sirius XM Shares, Sirius XM Price,
#   Q1 Math, Q1 Reading, Q2 Math, Q2 Reading, Q3 Math, Q3 Reading,
#   Absences Q1, Absences Q2, Absences Q3

require "csv"

VALID_GRADES = %w[A+ A A- B+ B B- C+ C C- D F].freeze

STOCK_HEADERS = [
  { shares_col: "Under Armour Shares", price_col: "Under Armour Price", ticker: "UA" },
  { shares_col: "Sony Shares",         price_col: "Sony Price",         ticker: "SONY" },
  { shares_col: "Gap Shares",          price_col: "Gap Price",          ticker: "GAP" },
  { shares_col: "Ford Shares",         price_col: "Ford Price",         ticker: "F" },
  { shares_col: "Southwest Shares",    price_col: "Southwest Price",    ticker: "LUV" },
  { shares_col: "Verizon Shares",      price_col: "Verizon Price",      ticker: "VZ" },
  { shares_col: "Sirius XM Shares",    price_col: "Sirius XM Price",    ticker: "SIRI" }
].freeze

GRADE_HEADERS = {
  1 => { math: "Q1 Math", reading: "Q1 Reading" },
  2 => { math: "Q2 Math", reading: "Q2 Reading" },
  3 => { math: "Q3 Math", reading: "Q3 Reading" }
}.freeze

ABSENCE_HEADERS = {
  1 => "Absences Q1",
  2 => "Absences Q2",
  3 => "Absences Q3"
}.freeze

# --- Helpers ---

def find_unique_username(base)
  return base unless User.exists?(username: base)

  suffix = 1
  loop do
    candidate = "#{base}#{suffix}"
    return candidate unless User.exists?(username: candidate)

    suffix += 1
  end
end

def normalize_grade(value)
  return nil if value.blank?

  grade = value.strip
  VALID_GRADES.include?(grade) ? grade : nil
end

def parse_currency(value)
  value.to_s.gsub(/[$,]/, "").strip.to_f
end

def quarterly_attendance_days(quarterly_absences)
  earnings_cents = [900 - (quarterly_absences * 20), 0].max
  earnings_cents / 20
end

# --- Main ---

csv_path     = ARGV.find { |a| !a.start_with?("--") }
dry_run      = ARGV.include?("--dry-run")
classroom_id_arg = ARGV.find { |a| a.start_with?("--classroom=") }
classroom_id     = classroom_id_arg&.split("=")&.last.to_i

unless csv_path
  puts "Usage: bin/rails runner #{$PROGRAM_NAME} <csv_path> --classroom=ID [--dry-run]"
  exit 1
end

unless classroom_id&.positive?
  puts "Error: --classroom=ID is required. e.g. --classroom=3"
  exit 1
end

unless File.exist?(csv_path)
  puts "Error: File not found: #{csv_path}"
  exit 1
end

classroom = Classroom.find_by(id: classroom_id)
unless classroom
  puts "Error: Classroom with ID #{classroom_id} not found."
  exit 1
end

school_year = classroom.school_year
unless school_year
  puts "Error: Classroom has no school year."
  exit 1
end

puts "=== Returning Student Migration ==="
puts "Classroom: #{classroom.name} (ID: #{classroom.id})"
puts "School Year: #{school_year.name}"
puts ""

missing_quarters = (1..3).select { |n| Quarter.find_by(school_year: school_year, number: n).nil? }
if missing_quarters.any?
  puts "Error: Missing quarters #{missing_quarters.join(', ')} for school year #{school_year.name}."
  puts "Quarters must exist before running this script."
  puts "Existing quarters: #{Quarter.where(school_year: school_year).order(:number).pluck(:number).inspect}"
  exit 1
end

# Ensure gradebooks exist for Q1-Q3 before processing students
(1..3).each do |quarter_num|
  quarter = Quarter.find_by(school_year: school_year, number: quarter_num)
  GradeBook.find_or_create_by!(quarter: quarter, classroom: classroom)
end

# Read CSV with named headers
csv = CSV.read(csv_path, headers: true)

# Validate required headers are present
required_headers = ["Username", "Current Earnings", "Remaining Balance",
                    "Q1 Math", "Q1 Reading", "Q2 Math", "Q2 Reading", "Q3 Math", "Q3 Reading",
                    "Absences Q1", "Absences Q2", "Absences Q3"]
missing_headers = required_headers.reject { |h| csv.headers.include?(h) }
if missing_headers.any?
  puts "Error: CSV is missing required headers: #{missing_headers.join(', ')}"
  puts "Found headers: #{csv.headers.compact.inspect}"
  exit 1
end

puts "Dry run: #{dry_run}"
puts "Processing #{csv.count} rows from CSV..."
puts ""

created_count = 0
skipped_count = 0
warnings = []
total_earnings_deposited = 0
total_purchases = 0
total_grade_entries = 0
student_results = []

csv.each do |row|
  username = row["Username"]&.strip
  next if username.blank?

  original_username = username
  username = find_unique_username(username)
  username_changed = username != original_username

  if User.exists?(username: username)
    skipped_count += 1
    warnings << "#{original_username}: already exists (mapped to #{username}), skipping."
    next
  end

  earnings = parse_currency(row["Current Earnings"])

  if dry_run
    puts "[DRY RUN] Would create student: #{username}#{" (was #{original_username})" if username_changed}"
    puts "[DRY RUN]   Last Year Earnings: $#{earnings}"
    (1..3).each do |q|
      raw_absences = row[ABSENCE_HEADERS[q]]
      if raw_absences.blank?
        puts "[DRY RUN]   Q#{q} Absences: (blank) -> skipping quarter, no grade entry"
        next
      end
      absences = raw_absences.to_f
      days = quarterly_attendance_days(absences)
      earnings_val = format("%.2f", days * 0.20)
      perfect = absences.zero? ? " (+$1.00 perfect)" : ""
      puts "[DRY RUN]   Q#{q} Absences: #{absences} -> attendance earnings: $#{earnings_val}#{perfect}"
    end
    STOCK_HEADERS.each do |stock|
      shares = row[stock[:shares_col]].to_i
      price  = parse_currency(row[stock[:price_col]])
      next if shares <= 0

      puts "[DRY RUN]   Purchase: #{stock[:ticker]} #{shares} shares @ $#{price} = $#{format('%.2f', shares * price)}"
    end
    puts ""
    created_count += 1
    next
  end

  ActiveRecord::Base.transaction do
    password = MemorablePasswordGenerator.generate
    student = Student.create!(
      username: username,
      type: "Student",
      classroom: classroom,
      email: nil,
      password: password,
      password_confirmation: password
    )
    created_count += 1

    earnings_cents = (earnings * 100).round
    if earnings.positive?
      student.portfolio.portfolio_transactions.create!(
        amount_cents: earnings_cents,
        transaction_type: :deposit,
        reason: :administrative_adjustments,
        description: "Prior year earnings migration"
      )
      total_earnings_deposited += earnings_cents
    end

    total_spent_cents = 0
    STOCK_HEADERS.each do |stock_cfg|
      shares = row[stock_cfg[:shares_col]].to_i
      price  = parse_currency(row[stock_cfg[:price_col]])
      next if shares <= 0 || price <= 0

      stock = Stock.find_by(ticker: stock_cfg[:ticker])
      unless stock
        warnings << "#{username}: Stock #{stock_cfg[:ticker]} not found, skipping purchase."
        next
      end

      cost_cents = (shares * price * 100).round
      student.portfolio.portfolio_transactions.create!(
        amount_cents: cost_cents,
        transaction_type: :debit,
        reason: :administrative_adjustments,
        description: "Retroactive stock purchase: #{stock.company_name}"
      )
      student.portfolio.portfolio_stocks.create!(
        stock: stock,
        shares: shares,
        purchase_price: price
      )
      total_spent_cents += cost_cents
      total_purchases += 1
    end

    expected_balance_cents   = (parse_currency(row["Remaining Balance"]) * 100).round
    calculated_balance_cents = earnings_cents - total_spent_cents
    discrepancy              = (calculated_balance_cents - expected_balance_cents).abs
    if discrepancy > 1
      warnings << "#{username}: Balance mismatch - expected $#{expected_balance_cents / 100.0}, calculated $#{calculated_balance_cents / 100.0} (diff: $#{discrepancy / 100.0})"
    end

    GRADE_HEADERS.each do |quarter_num, cols|
      raw_absences = row[ABSENCE_HEADERS[quarter_num]]
      if raw_absences.blank?
        warnings << "#{username}: Q#{quarter_num} absences blank, skipping grade entry."
        next
      end

      quarter    = Quarter.find_by(school_year: school_year, number: quarter_num)
      grade_book = GradeBook.find_or_create_by!(quarter: quarter, classroom: classroom)

      quarterly_absences = raw_absences.to_f

      GradeEntry.create!(
        grade_book: grade_book,
        user: student,
        math_grade: normalize_grade(row[cols[:math]]),
        reading_grade: normalize_grade(row[cols[:reading]]),
        attendance_days: quarterly_attendance_days(quarterly_absences),
        is_perfect_attendance: quarterly_absences.zero?
      )
      total_grade_entries += 1
    end
  end

  student_results << { username: username }
  puts "Created: #{username}#{" (was #{original_username})" if username_changed}"
end

puts ""

unless dry_run
  puts "--- Finalizing Grade Books ---"
  (1..3).each do |quarter_num|
    quarter    = Quarter.find_by(school_year: school_year, number: quarter_num)
    grade_book = GradeBook.find_or_create_by!(quarter: quarter, classroom: classroom)

    if grade_book.draft?
      grade_book.verified!
      DistributeEarnings.execute(grade_book)
      puts "Finalized: Quarter #{quarter_num} - #{grade_book.grade_entries.count} entries processed"
    else
      puts "Skipped: Quarter #{quarter_num} - already #{grade_book.status}"
    end
  end

  puts ""
  puts "--- Student Summary ---"
  student_results.each do |result|
    student = Student.find_by(username: result[:username])
    next unless student

    portfolio = student.portfolio

    this_year_earnings_cents = portfolio.portfolio_transactions
      .where(transaction_type: :deposit, reason: %i[attendance_earnings math_earnings reading_earnings])
      .sum(:amount_cents)

    holdings = portfolio.portfolio_stocks
      .joins(:stock)
      .where("portfolio_stocks.shares > 0")
      .pluck("stocks.ticker", "portfolio_stocks.shares", "portfolio_stocks.purchase_price")

    result[:last_year_earnings] = portfolio.portfolio_transactions
      .where(description: "Prior year earnings migration")
      .sum(:amount_cents)
    result[:this_year_earnings] = this_year_earnings_cents
    result[:cash_balance]       = portfolio.cash_balance
    result[:holdings]           = holdings
  end

  puts ""
  student_results.each do |result|
    puts "#{result[:username]}:"
    puts "  Last Year Earnings:  $#{result[:last_year_earnings] / 100.0}"
    puts "  This Year Earnings:  $#{result[:this_year_earnings] / 100.0}"
    puts "  Cash Balance:        $#{result[:cash_balance]}"
    if result[:holdings].any?
      puts "  Holdings:"
      result[:holdings].each { |ticker, shares, price| puts "    #{ticker}: #{shares} shares @ $#{price}" }
    else
      puts "  Holdings: none"
    end
    puts ""
  end
end

puts ""
puts "=== Migration Summary ==="
puts "Students created:              #{created_count}"
puts "Students skipped:              #{skipped_count}"
puts "Total earnings deposited:      $#{total_earnings_deposited / 100.0}"
puts "Total stock purchases:         #{total_purchases}"
puts "Total grade entries created:   #{total_grade_entries}"

if warnings.any?
  puts ""
  puts "Warnings (#{warnings.count}):"
  warnings.each { |w| puts "  - #{w}" }
end

if dry_run
  puts ""
  puts "This was a dry run. No changes were made."
  puts "Run without --dry-run to execute the migration."
end

# rubocop:enable Metrics/BlockLength, Layout/LineLength
