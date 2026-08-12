# frozen_string_literal: true

require "test_helper"

# design.md: a field the model requires says so on its label, with the red asterisk, and carries `required`
# for assistive technology.
#
# **Reported, and it was true of nine forms out of eighteen.** Only the two student forms, the classroom form
# and three Devise pages marked anything at all; a school's name, a stock's ticker, an announcement's title
# and content, a school year's school and year, a teacher's email, a user's username and password, and every
# field on the two money forms were all required by the model and silent in the interface.
#
# The asterisk is `.required-indicator` from `Ui::FormBuilder#required_indicator` - red-600, which measures
# 4.83:1 on white where red-500 measured 3.76:1 and failed AA. It is `aria-hidden`, because the `required`
# attribute is what a screen reader announces; the colour and the glyph are for everyone else.
#
# Native browser validation is off app-wide (`app/javascript/application.js`), so `required` here is not what
# stops a submit - the model is. That is the reason this test pairs them: **a mark with no validation behind
# it, and a validation with no mark, are the same defect in two directions.**
class RequiredFieldsTest < ActionDispatch::IntegrationTest
  # Each entry is a page and the field ids its model genuinely requires on that path.
  def admin_pages
    school = create(:school)
    year = create(:year)
    school_year = create(:school_year, school:, year:)
    classroom = create(:classroom, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    teacher = create(:teacher)
    stock = create(:stock)
    announcement = Announcement.create!(title: "Notice", content: "Body")
    transaction = create(:portfolio_transaction, portfolio: student.portfolio)

    {
      new_admin_school_path => %w[school_name],
      edit_admin_school_path(school) => %w[school_name],
      new_admin_school_year_path => %w[school_year_school_id school_year_year_id],
      new_admin_stock_path => %w[stock_ticker],
      edit_admin_stock_path(stock) => %w[stock_ticker],
      new_admin_announcement_path => %w[announcement_title announcement_content],
      edit_admin_announcement_path(announcement) => %w[announcement_title announcement_content],
      new_admin_teacher_path => %w[teacher_email],
      admin_teacher_path(teacher) => %w[teacher_email],
      new_admin_user_path => %w[user_username user_password user_password_confirmation],
      new_admin_student_path => %w[student_name student_username student_classroom_id],
      new_admin_portfolio_transaction_path =>
        %w[portfolio_transaction_portfolio_id portfolio_transaction_transaction_type
           portfolio_transaction_amount_cents],
      admin_portfolio_transaction_path(transaction) =>
        %w[portfolio_transaction_portfolio_id portfolio_transaction_transaction_type
           portfolio_transaction_amount_cents],
      admin_student_path(student) =>
        %w[student_name student_username student_classroom_id
           cash_adjustment_transaction_type cash_adjustment_amount cash_adjustment_reason]
    }
  end

  def assert_marked_required(path, ids)
    get path

    assert_response :success

    ids.each do |id|
      # The asterisk, inside the field's own label rather than anywhere on the page.
      assert_select "label[for=?] .required-indicator", id, { count: 1 },
                    "#{path}: #{id} is required by the model and its label carries no asterisk"
      # And the attribute, which is what assistive technology reads.
      assert_select "##{id}[required]", { count: 1 },
                    "#{path}: #{id} is required by the model and the control does not say so"
    end
  end

  test "every field the model requires is marked on the admin forms" do
    sign_in(create(:admin, admin: true, classroom: nil))

    admin_pages.each { |path, ids| assert_marked_required(path, ids) }
  end

  test "the teacher's own student form marks what it requires" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)

    assert_marked_required(new_classroom_student_path(classroom), %w[student_name student_username])
  end

  test "the signed-out pages mark what they require" do
    assert_marked_required(new_user_session_path, %w[user_username user_password])
    assert_marked_required(new_user_password_path, %w[user_email])
  end

  # The other direction, and the reason this file pairs the two: a mark has to mean the model would reject a
  # blank. `User#email_required?` is false for a student, so a student's profile shows no asterisk on the email
  # field, and a teacher's does.
  test "a conditional requirement is marked only when it applies" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.reload
    sign_in(student)

    get edit_profile_path

    assert_response :success
    assert_select "label[for='user_email'] .required-indicator", count: 0
    assert_select "#user_email[required]", count: 0

    teacher = create(:teacher)
    sign_in(teacher)

    get edit_profile_path

    assert_response :success
    assert_select "label[for='user_email'] .required-indicator", count: 1
    assert_select "#user_email[required]", count: 1
  end

  # An optional field must **not** be marked, or the asterisk stops meaning anything.
  test "optional fields carry no asterisk" do
    sign_in(create(:admin, admin: true, classroom: nil))

    get new_admin_stock_path

    assert_response :success
    %w[stock_company_name stock_company_website stock_description stock_employees].each do |id|
      assert_select "label[for=?] .required-indicator", id, { count: 0 },
                    "#{id} is optional in the model and its label claims otherwise"
    end
  end
end
