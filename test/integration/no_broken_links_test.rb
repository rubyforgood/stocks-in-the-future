# frozen_string_literal: true

require "test_helper"

# Every link the app renders resolves.
#
# "Nothing should 404, it should all be routed correctly." This crawls what each role is actually shown -
# navigation, breadcrumbs, page actions, row actions, empty-state calls to action - and requests every
# internal href it finds, for that same role.
#
# It asserts on the **rendered** page rather than on `config/routes.rb`, because a route can exist while
# the link that reaches it is wrong, and a link can be right while the record it names has gone. Those are
# the two ways a dead link happens here and neither is visible in the routes file.
class NoBrokenLinksTest < ActionDispatch::IntegrationTest
  # Signing out mid-crawl would make every later request a redirect to the sign-in page, which reports
  # nothing about the links themselves.
  SKIP = [%r{/users/sign_out}].freeze

  # **The verb the link declares, not GET.** A row action is a `link_to` carrying
  # `data-turbo-method="patch"`, and its href is routed for that verb only - so requesting it with GET
  # returns 404 and says nothing about whether the link works. Three of those were the crawl's first
  # "findings" and none of them was broken.
  #
  # That they 404 on GET is a real if separate matter - it is what a middle-click or a reader without
  # JavaScript gets - and `design-todo.md` carries it, because the fix is `button_to` and this repo has a
  # recorded case where a nested `button_to` broke a page.
  def internal_links(body)
    body.css("a[href]").filter_map do |a|
      href = a["href"]
      next if href.blank? || href.start_with?("#", "mailto:", "tel:", "http://", "https://")
      next if SKIP.any? { |pattern| href.match?(pattern) }

      [href, (a["data-turbo-method"] || "get").to_sym]
    end
  end

  def crawl(role, paths)
    seen = Set.new
    broken = []

    paths.each do |path|
      get path
      assert_response :success, "#{role}: the crawl's own starting page #{path} did not render"

      internal_links(response.parsed_body).each do |href, verb|
        next unless seen.add?([href, verb])

        if verb == :get
          get href
          broken << "GET #{href} -> #{response.status} (from #{path}, as #{role})" if response.status >= 400
          next
        end

        # **Routed, not requested.** Following a `data-turbo-method="delete"` link *performs* the delete:
        # the crawl archived a classroom and deactivated a teacher, and then its own next page failed to
        # render. `recognize_path` proves the href is wired for the verb the link declares, which is the
        # question, without doing the thing.
        begin
          Rails.application.routes.recognize_path(href, method: verb)
        rescue ActionController::RoutingError
          broken << "#{verb.to_s.upcase} #{href} -> no route (from #{path}, as #{role})"
        end
      end
    end

    assert_empty broken, "#{role} is shown links that do not resolve:\n  #{broken.join("\n  ")}"
    assert_operator seen.size, :>, 5, "#{role}: the crawl found almost no links, so it proved nothing"
  end

  # **No anchor performs an action.** An `<a href>` whose route answers only PATCH, POST or DELETE returns
  # 404 on a GET, so a middle-click, a new tab, a copied address or a reader without JavaScript all land
  # on the error page. There were 32 of them. They are `button_to` now - which is also the accessible
  # answer, since an element that acts rather than navigates is a button.
  #
  # Asserted on the rendered page because the source keeps `data: { turbo_method: }` as the *input* to
  # `ghost_action_link`, which converts it; grepping the templates would report 29 of these as unfixed.
  test "no page offers an action as a link" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500_000)
    stock = create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241)
    Announcement.create!(title: "Notice", content: "Body.")
    sign_in create(:admin)

    offenders = []
    [admin_root_path, admin_users_path, admin_user_path(student), admin_classrooms_path,
     admin_classroom_path(classroom), admin_students_path, admin_student_path(student),
     admin_teachers_path, admin_teacher_path(teacher), admin_stocks_path, admin_stock_path(stock),
     admin_announcements_path, admin_portfolio_transactions_path, admin_schools_path,
     admin_school_years_path, admin_school_year_path(school_year)].each do |path|
      get path

      response.parsed_body.css("a[data-turbo-method]").each do |a|
        offenders << "#{path}: #{a.text.squish.presence || a['href']} (#{a['data-turbo-method']})"
      end
    end

    assert_empty offenders, "these act but are links:\n  #{offenders.join("\n  ")}"
  end

  test "every link a student is shown resolves" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500_000)
    stock = create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241)
    create(:portfolio_stock, portfolio: student.portfolio, stock:, shares: 2)
    create(:order, user: student, stock:, shares: 1, status: :pending, action: :buy)
    Announcement.create!(title: "Half day", content: "Noon.")
    sign_in student

    crawl(
      "a student", [root_path, stocks_path, stock_path(stock), orders_path,
                    user_portfolio_path(student, student.portfolio)]
    )
  end

  test "every link a teacher is shown resolves" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    book = classroom.grade_books.first
    create(:grade_entry, grade_book: book, user: student)
    create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241)
    sign_in teacher

    crawl(
      "a teacher", [root_path, classrooms_path, classroom_path(classroom), stocks_path,
                    classroom_grade_book_path(classroom, book)]
    )
  end

  test "every link an admin is shown resolves" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500_000)
    create(:teacher_classroom, teacher: create(:teacher), classroom:)
    create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241)
    Announcement.create!(title: "Notice", content: "Body.")
    sign_in create(:admin)

    crawl(
      "an admin",
      [admin_root_path, admin_users_path, admin_classrooms_path, admin_students_path,
       admin_teachers_path, admin_stocks_path, admin_announcements_path,
       admin_portfolio_transactions_path, admin_schools_path, admin_school_years_path,
       admin_student_path(student), admin_classroom_path(classroom)]
    )
  end
end
