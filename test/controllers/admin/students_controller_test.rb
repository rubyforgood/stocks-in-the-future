# frozen_string_literal: true

require "test_helper"

module Admin
  class StudentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @classroom1 = create(:classroom)
      @classroom2 = create(:classroom)
      @admin = create(:admin, admin: true, classroom: nil)
      sign_in(@admin)
    end

    test "index" do
      create(:student)
      create(:student)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_students_path

      assert_response :success
      assert_select "h1", "Students"
      assert_select "tbody tr", count: 2
    end

    test "index with discarded filter" do
      student = create(:student, :discarded)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_students_path(discarded: true)

      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "form[action=?]", restore_admin_student_path(student) do
        assert_select "button", text: "Restore"
      end
    end

    test "index with all filter" do
      create(:student)
      create(:student)
      create(:student, :discarded)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_students_path(all: true)

      assert_response :success
      assert_select "tbody tr", count: 3
      # Scoped to the actions column, because below lg the row's actions are rendered a second time
      # inside the primary cell - the collapse that stops the table scrolling sideways at 375px. Only
      # one copy is ever on screen, but a request test has no CSS and counts both.
      #
      # Scoped to the table body as well: as `a[href*='edit']` this also counted the account menu's
      # "Edit profile" link, so adding a profile page broke a test about student rows.
      assert_select "tbody td.table-actions-pinned a[href*='/edit']", count: 2
    end

    test "show" do
      username = "finn"
      student = create(:student, username:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_student_path(student)

      assert_response :success
      assert_select "h1", username
      assert_select "h2", text: "Portfolio details"
      assert_select(
        "[data-testid='cash_balance_label']",
        text: "Cash balance"
      )
      assert_select(
        "[data-testid='total_portfolio_worth_label']",
        text: "Total portfolio worth"
      )
    end

    test "show displays attendance records" do
      student = create(:student)
      quarter = student.classroom.school_year.quarters.find_by!(number: 1)
      grade_book = student.classroom.grade_books.find_by!(quarter: quarter)
      create(:grade_entry, grade_book: grade_book, user: student, attendance_days: 42, is_perfect_attendance: true)

      get admin_student_path(student)

      assert_response :success
      assert_select "h2", text: "Attendance"
      assert_select "tbody tr", minimum: 1
      # A regex, not an exact string: below lg this table reflows and each cell carries a visible
      # label, so the cell's text is "Quarter Q1" rather than "Q1". The label is markup at every
      # width, which is what a request test sees.
      assert_select "td", text: /\bQ1\b/
      assert_select "td", text: /\b42\b/
    end

    test "show displays empty attendance message when no records" do
      student = create(:student)

      get admin_student_path(student)

      assert_response :success
      assert_select "p", text: "No attendance records found."
    end

    test "show displays earnings summary" do
      student = create(:student)
      portfolio = student.portfolio
      portfolio.portfolio_transactions.create!(
        amount_cents: 500, transaction_type: :deposit,
        reason: :attendance_earnings
      )
      portfolio.portfolio_transactions.create!(amount_cents: 300, transaction_type: :deposit, reason: :math_earnings)
      portfolio.portfolio_transactions.create!(amount_cents: 200, transaction_type: :deposit, reason: :awards)

      get admin_student_path(student)

      assert_response :success
      assert_select "h3", text: "Earnings summary"
      assert_select "td", text: "Attendance earnings"
      assert_select "td", text: "Math earnings"
      assert_select "td", text: "Rewards"
      assert_select "td", text: "Total earnings"
      assert_select "td", text: "Transaction fees"
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_student_path

      assert_response :success
      assert_select "h1", "New student"
    end

    test "create" do
      username = "jake"
      classroom = create(:classroom, name: "Ice Kingdom")
      params = {
        student: {
          name: "Test Student",
          username:,
          classroom_id: classroom.id,
          password: "password123",
          password_confirmation: "password123"
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference(["Student.count", "Portfolio.count"]) do
        post(admin_students_path, params:)
      end
      student = Student.last

      assert_redirected_to admin_student_path(student)
      assert_equal(
        "Student #{username} created successfully. Password: password123",
        flash[:notice]
      )
      assert_not_nil student.portfolio
    end

    test "create with invalid params" do
      params = { student: { username: "", classroom_id: nil } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Student.count") do
        post(admin_students_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      student = create(:student)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_student_path(student)

      assert_response :success
      assert_select "h1", "Edit student"
    end

    test "update" do
      username = "marceline"
      student = create(:student)
      params = { student: { username: } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_student_path(student), params:)
      student.reload

      assert_redirected_to admin_student_path(student)
      assert_equal "Student updated successfully.", flash[:notice]
      assert_equal username, student.username
    end

    test "update with invalid params" do
      student = create(:student)
      params = { student: { username: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_student_path(student), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      username = "gunter"
      student = create(:student, username:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Student.count") do
        delete admin_student_path(student)
      end
      student.reload

      assert_redirected_to admin_students_path
      assert_equal "Student #{username} archived successfully.", flash[:notice]
      assert student.discarded?
    end

    test "restore" do
      username = "lsp"
      student = create(:student, :discarded, username:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch restore_admin_student_path(student)
      student.reload

      assert_redirected_to admin_students_path(discarded: true)
      assert_equal "Student #{username} restored successfully.", flash[:notice]
      assert_not student.discarded?
    end

    test "add_transaction" do
      portfolio = build(:portfolio, user: nil)
      student = create(:student, portfolio:)
      create(:portfolio_transaction, :deposit, portfolio:, amount_cents: 10_000)
      params = {
        transaction_type: "deposit",
        add_fund_amount: "100.50",
        transaction_reason: "awards",
        transaction_description: "Test deposit"
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      post(add_transaction_admin_student_path(student), params:)
      portfolio.reload

      assert_redirected_to admin_student_path(student)
      assert_equal "Transaction added successfully.", flash[:notice]
      assert_equal 20_050, portfolio.cash_balance * 100
    end

    test "add_transaction debit" do
      student = create(:student)
      params = {
        transaction_type: "debit",
        add_fund_amount: "50.25",
        transaction_reason: "administrative_adjustments",
        transaction_description: "Test debit"
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      post(add_transaction_admin_student_path(student), params:)
      transaction = student.portfolio.portfolio_transactions.last

      assert_redirected_to admin_student_path(student)
      assert_equal "debit", transaction.transaction_type
      assert_equal 5_025, transaction.amount_cents
    end

    test "add_transaction invalid params" do
      student = create(:student)
      params = { transaction_type: "" }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      post(add_transaction_admin_student_path(student), params:)
      expected_error_message =
        "Transaction type must be present, Amount must be present, " \
        "Reason must be present"

      assert_redirected_to edit_admin_student_path(student)
      assert_equal expected_error_message, flash[:alert]
    end

    test "add_transaction params are not nested under student key" do
      student = create(:student)
      params = {
        student: {
          transaction_type: "deposit",
          add_fund_amount: "50.00",
          transaction_reason: "awards",
          transaction_description: "Nested params should be ignored"
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("PortfolioTransaction.count") do
        post(add_transaction_admin_student_path(student), params:)
      end

      assert_redirected_to edit_admin_student_path(student)
    end

    # Import/Template tests
    test "template should download CSV template" do
      get template_admin_students_path

      assert_response :success
      assert_equal "text/csv", response.media_type
      assert_includes response.headers["Content-Disposition"], "attachment; filename=\"student_import_template.csv\""
      assert_match(/classroom_id,username,name/, response.body)
    end

    test "import should create students from valid CSV" do
      csv_content = "classroom_id,username,name\n" \
                    "#{@classroom1.id},import_student1,Import One\n" \
                    "#{@classroom2.id},import_student2,Import Two"
      csv_file = Tempfile.new(["test_import", ".csv"])
      csv_file.write(csv_content)
      csv_file.rewind

      assert_difference("Student.count", 2) do
        post import_admin_students_path, params: {
          csv_file: fixture_file_upload(csv_file.path, "text/csv")
        }
      end

      csv_file.close
      csv_file.unlink

      assert_redirected_to admin_students_path
      assert_match(/Successfully created 2 students/, flash[:notice])
      assert_match(/import_student1/, flash[:notice])
      assert_match(/import_student2/, flash[:notice])
    end

    test "import should skip existing students" do
      create(:student, username: "student1", classroom: @classroom1)
      csv_content = "classroom_id,username,name\n" \
                    "#{@classroom1.id},student1,Existing One\n" \
                    "#{@classroom2.id},new_student,New Student"
      csv_file = Tempfile.new(["test_import", ".csv"])
      csv_file.write(csv_content)
      csv_file.rewind

      assert_difference("Student.count", 1) do
        post import_admin_students_path, params: {
          csv_file: fixture_file_upload(csv_file.path, "text/csv")
        }
      end

      csv_file.close
      csv_file.unlink

      assert_redirected_to admin_students_path
      assert_match(/Successfully created 1 students/, flash[:notice])
      assert_match(/Skipped 1 row: Student with username .student1. already exists/, flash[:notice])
    end

    test "import should handle errors and show line numbers" do
      csv_content = "classroom_id,username,name\n" \
                    "999,invalid_student,Invalid One\n" \
                    "#{@classroom1.id},valid_student,Valid One"
      csv_file = Tempfile.new(["test_import", ".csv"])
      csv_file.write(csv_content)
      csv_file.rewind

      post import_admin_students_path, params: {
        csv_file: fixture_file_upload(csv_file.path, "text/csv")
      }

      csv_file.close
      csv_file.unlink

      assert_redirected_to admin_students_path
      assert_match(/errors occurred/, flash[:alert])
      assert_match(/Row 2:/, flash[:alert])
    end

    test "import should reject missing file" do
      assert_no_difference("Student.count") do
        post import_admin_students_path
      end

      assert_redirected_to admin_students_path
      assert_equal I18n.t("admin.students.import.errors.no_file"), flash[:alert]
    end

    test "import should handle malformed CSV" do
      csv_content = "classroom_id,username,name\n1,\"unclosed quote\n2,another_row,Name"
      csv_file = Tempfile.new(["test_import", ".csv"])
      csv_file.write(csv_content)
      csv_file.rewind

      assert_no_difference("Student.count") do
        post import_admin_students_path, params: {
          csv_file: fixture_file_upload(csv_file.path, "text/csv")
        }
      end

      csv_file.close
      csv_file.unlink

      assert_redirected_to admin_students_path
      assert_match(/Invalid CSV format/, flash[:alert])
    end

    test "import should handle empty CSV" do
      csv_content = "classroom_id,username,name\n"
      csv_file = Tempfile.new(["test_import", ".csv"])
      csv_file.write(csv_content)
      csv_file.rewind

      assert_no_difference("Student.count") do
        post import_admin_students_path, params: {
          csv_file: fixture_file_upload(csv_file.path, "text/csv")
        }
      end

      csv_file.close
      csv_file.unlink

      assert_redirected_to admin_students_path
      assert_equal I18n.t("admin.students.import.errors.no_students"), flash[:alert]
    end

    test "import should show both success and error messages" do
      csv_content = "classroom_id,username,name\n" \
                    "#{@classroom1.id},import_success1,Success One\n" \
                    "999,import_fail,Fail One\n" \
                    "#{@classroom2.id},import_success2,Success Two"
      csv_file = Tempfile.new(["test_import", ".csv"])
      csv_file.write(csv_content)
      csv_file.rewind

      post import_admin_students_path, params: {
        csv_file: fixture_file_upload(csv_file.path, "text/csv")
      }

      csv_file.close
      csv_file.unlink

      assert_redirected_to admin_students_path
      assert_match(/Successfully created 2 students/, flash[:notice])
      assert_match(/1 errors occurred/, flash[:alert])
    end

    # The report describes a skip by its actual reason rather than assuming one.
    #
    # It said "Skipped N existing usernames", which was true only while a duplicate was the sole thing
    # that could produce a skip. A nameless row briefly landed in that bucket and was reported to the
    # admin as a duplicate. Two mitigations, and this covers both: a missing required field is a failure
    # now, and the skip wording is derived from the messages so it cannot drift from the cause again.
    test "import describes a skipped row by its reason" do
      create(:student, username: "already_here", classroom: @classroom1, name: "Already Here")
      csv_content = "classroom_id,username,name\n" \
                    "#{@classroom1.id},already_here,Duplicate Row\n" \
                    "#{@classroom1.id},brand_new,Brand New"

      post_csv(csv_content)

      assert_match(/Skipped 1 row/, flash[:notice])
      assert_match(/already exists/, flash[:notice])
      assert_no_match(/existing usernames/, flash[:notice])
    end

    # A row missing a required field is reported per row, in the failure list, where an operator fixing a
    # spreadsheet can see which line to edit - not counted as a skip.
    test "import reports a row missing a required field as a failure" do
      csv_content = "classroom_id,username,name\n" \
                    "#{@classroom1.id},no_name_here,\n" \
                    "#{@classroom1.id},fine_row,Fine Row"

      post_csv(csv_content)

      assert_match(/1 errors occurred/, flash[:alert])
      assert_match(/Name is required/, flash[:alert])
      assert_nil Student.find_by(username: "no_name_here")
      assert_not_nil Student.find_by(username: "fine_row")
    end

    def post_csv(content)
      file = Tempfile.new(["test_import", ".csv"])
      file.write(content)
      file.rewind
      post import_admin_students_path, params: { csv_file: fixture_file_upload(file.path, "text/csv") }
    ensure
      file.close
      file.unlink
    end

    test "non-admin cannot access template" do
      sign_out(@admin)
      teacher = create(:teacher)
      sign_in(teacher)

      get template_admin_students_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "non-admin cannot import students" do
      sign_out(@admin)
      teacher = create(:teacher)
      sign_in(teacher)

      csv_content = "classroom_id,username\n#{@classroom1.id},import_student"
      csv_file = Tempfile.new(["test_import", ".csv"])
      csv_file.write(csv_content)
      csv_file.rewind

      assert_no_difference("Student.count") do
        post import_admin_students_path, params: {
          csv_file: fixture_file_upload(csv_file.path, "text/csv")
        }
      end

      csv_file.close
      csv_file.unlink

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end
  end
end
