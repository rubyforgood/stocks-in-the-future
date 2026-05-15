#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Layout/LineLength

# Usage: RAILS_ENV=production bin/rails runner script/migrate_returning_students.rb path/to/students.csv [--dry-run]

require "csv"

# --- Constants ---

TARGET_CLASSROOM_ID = 1

# Column positions in the CSV (0-indexed)
COL = {
  username: 0,
  earnings: 6,
  remaining_balance: 8,
  ua_shares: 17,
  ua_price: 18,
  sony_shares: 19,
  sony_price: 20,
  gap_shares: 21,
  gap_price: 22,
  ford_shares: 23,
  ford_price: 24,
  southwest_shares: 25,
  southwest_price: 26,
  verizon_shares: 27,
  verizon_price: 28,
  sirius_shares: 29,
  sirius_price: 30,
  q1_math: 31,
  q1_reading: 32,
  q2_math: 33,
  q2_reading: 34,
  q3_math: 35,
  q3_reading: 36,
  absences_q1: 39,
  absences_q2: 40,
  absences_q3: 41
}.freeze

STOCK_COLUMNS = [
  { shares_col: COL[:ua_shares], price_col: COL[:ua_price], ticker: "UA" },
  { shares_col: COL[:sony_shares], price_col: COL[:sony_price], ticker: "SONY" },
  { shares_col: COL[:gap_shares], price_col: COL[:gap_price], ticker: "GPS" },
  { shares_col: COL[:ford_shares], price_col: COL[:ford_price], ticker: "F" },
  { shares_col: COL[:southwest_shares], price_col: COL[:southwest_price], ticker: "LUV" },
  { shares_col: COL[:verizon_shares], price_col: COL[:verizon_price], ticker: "VZ" },
  { shares_col: COL[:sirius_shares], price_col: COL[:sirius_price], ticker: "SIRI" }
].freeze

GRADE_COLUMNS = {
  1 => { math: COL[:q1_math], reading: COL[:q1_reading] },
  2 => { math: COL[:q2_math], reading: COL[:q2_reading] },
  3 => { math: COL[:q3_math], reading: COL[:q3_reading] }
}.freeze

MAX_DAYS_PER_QUARTER = 45

VALID_GRADES = %w[A+ A A- B+ B B- C+ C C- D F].freeze

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

ABSENCE_COLS = {
  1 => COL[:absences_q1],
  2 => COL[:absences_q2],
  3 => COL[:absences_q3]
}.freeze

def parse_currency(value)
  value.to_s.gsub(/[$,]/, "").strip.to_f
end

def quarterly_attendance_days(quarterly_absences)
  earnings_cents = [900 - (quarterly_absences * 20), 0].max
  earnings_cents / 20
end

# --- Main ---

csv_path = ARGV.find { |a| !a.start_with?("--") }
dry_run = ARGV.include?("--dry-run")

unless csv_path
  puts "Usage: bin/rails runner #{$PROGRAM_NAME} <csv_path> [--dry-run]"
  exit 1
end

unless File.exist?(csv_path)
  puts "Error: File not found: #{csv_path}"
  exit 1
end

classroom = Classroom.find_by(id: TARGET_CLASSROOM_ID)
unless classroom
  puts "Error: Classroom with ID #{TARGET_CLASSROOM_ID} not found."
  exit 1
end

puts "=== Returning Student Migration ==="
puts "Classroom: #{classroom.name} (ID: #{classroom.id})"
puts "School Year: #{classroom.school_year&.name}"
puts "Dry run: #{dry_run}"
puts ""

csv = CSV.read(csv_path, headers: false)
csv.shift # discard header row
puts "Processing #{csv.count} rows from CSV..."
puts ""

created_count = 0
skipped_count = 0
warnings = []
passwords = {}
total_earnings_deposited = 0
total_purchases = 0
total_grade_entries = 0
student_results = []

csv.each do |row|
  username = row[COL[:username]]&.strip
  next if username.blank?

  original_username = username
  username = find_unique_username(username)
  username_changed = username != original_username

  if User.exists?(username: username)
    skipped_count += 1
    warnings << "#{original_username}: already exists (mapped to #{username}), skipping."
    next
  end

  earnings = parse_currency(row[COL[:earnings]])

  if dry_run
    puts "[DRY RUN] Would create student: #{username}"
    puts "[DRY RUN]   Original: #{original_username}#{' (renamed)' if username_changed}"
    puts "[DRY RUN]   Last Year Earnings: $#{earnings}"
    (1..3).each do |q|
      absences = row[ABSENCE_COLS[q]].to_f
      days = quarterly_attendance_days(absences)
      earnings_val = format("%.2f", days * 0.20)
      perfect = absences.zero? ? " (+$1.00 perfect)" : ""
      puts "[DRY RUN]   Q#{q} Absences: #{absences} -> attendance earnings: $#{earnings_val}#{perfect}"
    end
    STOCK_COLUMNS.each do |stock|
      shares = row[stock[:shares_col]].to_i
      price = parse_currency(row[stock[:price_col]])
      next if shares <= 0

      cost = shares * price
      puts "[DRY RUN]   Purchase: #{stock[:ticker]} #{shares} shares @ $#{price} = $#{cost}"
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
    passwords[username] = password
    created_count += 1

    if earnings.positive?
      earnings_cents = (earnings * 100).round
      student.portfolio.portfolio_transactions.create!(
        amount_cents: earnings_cents,
        transaction_type: :deposit,
        reason: :administrative_adjustments,
        description: "Prior year earnings migration"
      )
      total_earnings_deposited += earnings_cents
    end

    total_spent_cents = 0
    STOCK_COLUMNS.each do |stock_cfg|
      shares = row[stock_cfg[:shares_col]].to_i
      price = parse_currency(row[stock_cfg[:price_col]])
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
        description: "Prior year stock purchase: #{stock.company_name}"
      )
      student.portfolio.portfolio_stocks.create!(
        stock: stock,
        shares: shares,
        purchase_price: price
      )
      total_spent_cents += cost_cents
      total_purchases += 1
    end

    expected_balance_cents = (parse_currency(row[COL[:remaining_balance]]) * 100).round
    calculated_balance_cents = earnings_cents - total_spent_cents
    discrepancy = (calculated_balance_cents - expected_balance_cents).abs
    if discrepancy > 1
      warnings << "#{username}: Balance mismatch - expected $#{expected_balance_cents / 100.0}, calculated $#{calculated_balance_cents / 100.0} (diff: $#{discrepancy / 100.0})"
    end

    school_year = classroom.school_year
    GRADE_COLUMNS.each do |quarter_num, cols|
      quarter = Quarter.find_by(school_year: school_year, number: quarter_num)
      unless quarter
        warnings << "#{username}: Quarter #{quarter_num} not found for school year, skipping grade entry."
        next
      end

      grade_book = GradeBook.find_or_create_by!(quarter: quarter, classroom: classroom)

      quarterly_absences = row[ABSENCE_COLS[quarter_num]].to_f

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
  school_year = classroom.school_year
  (1..3).each do |quarter_num|
    quarter = Quarter.find_by(school_year: school_year, number: quarter_num)
    next unless quarter

    grade_book = GradeBook.find_by(classroom: classroom, quarter: quarter)
    next unless grade_book

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
    result[:cash_balance] = portfolio.cash_balance
    result[:holdings] = holdings
  end

  puts ""
  student_results.each do |result|
    puts "#{result[:username]}:"
    puts "  Last Year Earnings:  $#{result[:last_year_earnings] / 100.0}"
    puts "  This Year Earnings:  $#{result[:this_year_earnings] / 100.0}"
    puts "  Cash Balance:        $#{result[:cash_balance]}"
    if result[:holdings].any?
      puts "  Holdings:"
      result[:holdings].each do |ticker, shares, price|
        puts "    #{ticker}: #{shares} shares @ $#{price}"
      end
    else
      puts "  Holdings: none"
    end
    puts ""
  end
end

puts ""
puts "=== Migration Summary ==="
puts "Students created: #{created_count}"
puts "Students skipped: #{skipped_count}"
puts "Total earnings deposited: $#{total_earnings_deposited / 100.0}"
puts "Total stock purchases recorded: #{total_purchases}"
puts "Total grade entries created: #{total_grade_entries}"

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
