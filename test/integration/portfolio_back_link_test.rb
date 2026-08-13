# frozen_string_literal: true

require "test_helper"

# A portfolio somebody else owns needs a way back to where you came from.
#
# Reported: from `admin/students#show`, whose "View portfolio" button is the only link out of that page, an
# admin landed on the portfolio with nothing to return by. The page renders in the **app** layout, which has
# no breadcrumb trail - trails are the admin half's convention - so the browser's Back button was the whole
# of it.
#
# A back link rather than a trail, because that is what this half uses: `stocks#show` has "Back to trading
# floor" in the same header slot. The destination is per role because the two readers arrive from two
# different places - an admin from the student's record, a teacher from their classroom roster, where the
# student's name is the link.
class PortfolioBackLinkTest < ActionDispatch::IntegrationTest
  def a_student_with_a_portfolio
    classroom = create(:classroom, :with_trading, name: "Period 3")
    student = create(:student, :with_portfolio, classroom:, name: "Robin Fields")
    student.reload
    student
  end

  def back_link
    response.parsed_body.css("main a").find { |a| a.text.strip.start_with?("Back to") }
  end

  test "an admin gets a link back to the student's record" do
    student = a_student_with_a_portfolio
    sign_in(create(:admin, admin: true, classroom: nil))

    get user_portfolio_path(student, student.portfolio)

    assert_response :success
    assert back_link, "an admin arrives from admin/students#show and had no way back"
    assert_equal "Back to Robin Fields", back_link.text.strip
    assert_equal admin_student_path(student), back_link["href"]
  end

  test "a teacher gets a link back to the classroom they came from" do
    student = a_student_with_a_portfolio
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom: student.classroom)
    sign_in(teacher)

    get user_portfolio_path(student, student.portfolio)

    assert_response :success
    assert back_link, "a teacher arrives from their classroom roster and had no way back"
    assert_equal "Back to Period 3", back_link.text.strip
    assert_equal classroom_path(student.classroom), back_link["href"]
  end

  # The owner reached this from the nav, which is also how they leave. A back link there would point at a
  # page they were not on.
  test "the owner gets no back link" do
    student = a_student_with_a_portfolio
    sign_in(student)

    get user_portfolio_path(student, student.portfolio)

    assert_response :success
    assert_nil back_link, "a student on their own portfolio arrived from the nav, not from a record"
  end
end
