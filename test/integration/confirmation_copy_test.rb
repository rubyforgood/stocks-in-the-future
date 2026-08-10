# frozen_string_literal: true

require "test_helper"

# Every confirmation is a question and a consequence.
#
# `shared/_confirm_dialog` splits its message on the first blank line: the question becomes the title,
# what follows becomes the body beneath it. Pass one string and the body stays hidden, leaving a dialog
# that can only restate the button - "Are you sure?", which is the phrasing that component was written
# to replace. Twenty-nine call sites did that, including three that said no more than "are you sure".
#
# This walks the pages that carry destructive actions and reads the attribute as rendered, because the
# alternative - grepping the source - cannot see a message built by a helper, and most of them now are.
class ConfirmationCopyTest < ActionDispatch::IntegrationTest
  # A body has to be a sentence, not a word. The shortest legitimate one here is about 60 characters.
  MIN_BODY = 40

  def confirmations
    response.parsed_body.css("[data-turbo-confirm]").pluck("data-turbo-confirm")
  end

  def assert_two_part_confirmations(path)
    get path

    assert_response :success
    found = confirmations

    found.each do |message|
      question, body = message.split(/\n\s*\n/, 2)

      assert body.present?,
             "#{path}: \"#{question}\" has no consequence - the dialog's body would stay hidden"
      assert_operator body.strip.length, :>=, MIN_BODY,
                      "#{path}: \"#{question}\" has a consequence too short to say anything: #{body.strip.inspect}"
      assert_no_match(
        /are you sure/i, question,
        "#{path}: a confirmation still asks \"are you sure\" instead of naming the action"
      )
    end

    found
  end

  test "every confirmation on the admin pages asks and explains" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    create(:stock, ticker: "KO", price_cents: 100)
    sign_in(create(:admin))

    seen = [admin_classrooms_path, admin_classroom_path(classroom), admin_teachers_path,
            admin_teacher_path(teacher), edit_admin_teacher_path(teacher), admin_students_path,
            admin_student_path(student), admin_users_path, admin_school_years_path,
            admin_stocks_path, admin_portfolio_transactions_path,
            admin_component_demo_index_path].flat_map { |path| assert_two_part_confirmations(path) }

    assert_operator seen.size, :>=, 10,
                    "expected these pages to carry confirmations - if they do not, this asserts nothing"
  end

  test "every confirmation a teacher or student meets asks and explains" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "KO", price_cents: 100)
    # A buy: the factory defaults to a sell, which needs shares the student does not own.
    create(:order, user: student, stock:, shares: 1, status: :pending, action: :buy)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)

    sign_in(teacher)
    assert_two_part_confirmations(classroom_path(classroom))

    sign_in(student)

    assert_operator assert_two_part_confirmations(orders_path).size, :>=, 1,
                    "expected the cancel-order confirmation"
  end
end
