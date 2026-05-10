#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Layout/LineLength

# Usage: RAILS_ENV=production bin/rails runner script/migrate_returning_students.rb path/to/students.csv [--dry-run]

require "csv"

# --- Constants ---

TARGET_CLASSROOM_ID = 1

STOCK_COLUMNS = [
  { shares_col: "Under Armour Shares", price_col: "Under Armour Price", ticker: "UA" },
  { shares_col: "Sony Shares", price_col: "Sony Price", ticker: "SONY" },
  { shares_col: "Gap Shares", price_col: "Gap Price", ticker: "GPS" },
  { shares_col: "Ford Shares", price_col: "Ford Price", ticker: "F" },
  { shares_col: "Southwest Shares", price_col: "Southwest Price", ticker: "LUV" },
  { shares_col: "Verizon Shares", price_col: "Verizon Price", ticker: "VZ" },
  { shares_col: "Sirius XM Shares", price_col: "Sirius XM Price", ticker: "SIRI" }
].freeze

GRADE_COLUMNS = {
  1 => { math: "Q1 Math", reading: "Q1 Reading" },
  2 => { math: "Q2 Math", reading: "Q2 Reading" },
  3 => { math: "Q3 Math", reading: "Q3 Reading" },
  4 => { math: "Q4 Math", reading: "Q4 Reading" }
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

ABSENCE_COLUMNS = {
  1 => "Q1 Absences",
  2 => "Q2 Absences",
  3 => "Q3 Absences",
  4 => "Q4 Absences"
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

csv = CSV.read(csv_path, headers: true)
puts "Processing #{csv.count} rows from CSV..."
puts ""

created_count = 0
skipped_count = 0
warnings = []
passwords = {}
total_earnings_deposited = 0
total_purchases = 0
total_grade_entries = 0

csv.each do |row|
  username = row["username"]&.strip
  next if username.blank?

  original_username = username
  username = find_unique_username(username)
  username_changed = username != original_username

  if User.exists?(username: username)
    skipped_count += 1
    warnings << "#{original_username}: already exists (mapped to #{username}), skipping."
    next
  end

  earnings = parse_currency(row["last year earnings"])
  if earnings <= 0
    warnings << "#{username}: invalid earnings value (#{row['last year earnings']}), skipping."
    next
  end

  if dry_run
    puts "[DRY RUN] Would create student: #{username}"
    puts "[DRY RUN]   Original: #{original_username}#{' (renamed)' if username_changed}"
    puts "[DRY RUN]   Earnings: $#{earnings}"
    (1..4).each do |q|
      absences = row[ABSENCE_COLUMNS[q]].to_i
      puts "[DRY RUN]   Q#{q} Absences: #{absences} -> attendance earnings: $#{quarterly_attendance_days(absences) * 0.20}"
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

    earnings_cents = (earnings * 100).round
    student.portfolio.portfolio_transactions.create!(
      amount_cents: earnings_cents,
      transaction_type: :deposit,
      reason: :administrative_adjustments,
      description: "Prior year earnings migration"
    )
    total_earnings_deposited += earnings_cents

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

    expected_balance_cents = (parse_currency(row["Remaining Balance"]) * 100).round
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

      quarterly_absences = row[ABSENCE_COLUMNS[quarter_num]].to_i

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

  puts "Created: #{username}#{" (was #{original_username})" if username_changed}"
end

puts ""

unless dry_run
  puts "--- Finalizing Grade Books ---"
  school_year = classroom.school_year
  (1..4).each do |quarter_num|
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
