# frozen_string_literal: true

require "application_system_test_case"

# Photographs every empty state in the product, into `public/preview/`, and checks it says something.
#
# **They cannot be seen any other way.** An empty state renders only when a list is empty, and the development
# database has data in every table - so the one screen a first-time admin or a brand-new student actually
# meets is the one nobody ever looks at. A test is the only place the data can be controlled, which is what
# makes this a test rather than a script.
#
# design.md's rule: at the moment it shows, an empty state is the only content on the page, so it says what
# the thing is or how rows arrive - never "No X found", which tells a reader nothing they cannot see.
#
# Set `PREVIEW=1` to write the images; without it the assertions still run and CI accumulates no screenshots.
class EmptyStatePreviewTest < ApplicationSystemTestCase
  PREVIEW_DIR = Rails.public_path.join("preview")

  # A body has to be a sentence: what this is, or how a row gets here.
  MIN_BODY = 30

  STATE = <<~JS
    (function () {
      const el = document.querySelector("[data-testid='empty-state']");
      if (!el) return null;
      const heading = el.querySelector("h2, h3, p.font-medium, p.text-base");
      const body = [...el.querySelectorAll("p")].map((p) => p.innerText.trim()).filter(Boolean);
      return { title: (heading ? heading.innerText : "").trim(), body: body.join(" ") };
    })()
  JS

  def capture(name)
    return unless ENV["PREVIEW"] == "1"

    FileUtils.mkdir_p(PREVIEW_DIR)
    page.driver.browser.save_screenshot(PREVIEW_DIR.join("empty-#{name}.png").to_s)
  end

  def assert_empty_state(name, expected_title)
    state = page.evaluate_script(STATE)

    assert state, "#{name}: no empty state rendered, so this page's empty case is untested"
    assert_equal expected_title, state["title"], "#{name}: unexpected empty-state title"
    assert_operator state["body"].length, :>=, MIN_BODY,
                    "#{name}: the body is a fragment, and it is the only content on the page"
    words = "#{state['title']} #{state['body']}"
    phrasing = "#{name}: \"No X found\" tells a reader nothing they cannot see"

    assert_no_match(/no .+ found/i, words, phrasing)

    capture(name)
  end

  # `admin/users` is not here: you are signed in as a user to see that page, so its unfiltered list can never
  # be empty. Its empty state is reachable only through the Archived tab, below.
  test "the admin lists' empty states" do
    sign_in create(:admin)

    { "students" => [admin_students_path, "No students yet"],
      "teachers" => [admin_teachers_path, "No teachers yet"],
      "classrooms" => [admin_classrooms_path, "No classrooms yet"],
      "school-years" => [admin_school_years_path, "No school years yet"],
      "transactions" => [admin_portfolio_transactions_path, "No transactions yet"] }.each do |name, (path, title)|
      visit path
      assert_empty_state(name, title)
    end
  end

  # **The Archived tab is a different sentence.** With nothing archived these said "No students yet" and
  # offered a New button - on a list of archived records, with plenty of unarchived ones a tab away. Both
  # halves were false, and it is the state a reader meets most often, because most installations archive
  # nothing.
  test "the archived tabs say what is missing" do
    create(:student, classroom: create(:classroom, :with_trading))
    create(:teacher)
    sign_in create(:admin)

    { "students-archived" => [admin_students_path(discarded: true), "No archived students"],
      "teachers-archived" => [admin_teachers_path(discarded: true), "No archived teachers"],
      "users-archived" => [admin_users_path(discarded: true), "No archived users"] }.each do |name, (path, title)|
      visit path
      assert_empty_state(name, title)
      # The page header keeps its New button - you can always create one - but the empty state must not
      # offer an action that would put nothing in the list you are looking at.
      assert_no_selector "[data-testid='empty-state'] a"
    end
  end

  # **Two sentences: what the thing is, then what appears here.** Set by a reader on the students list -
  # "Archiving a student is reversible and keeps their history and records intact. Archived students appear
  # here." - and applied to every empty state in the app.
  #
  # The second sentence is the one that was missing. Half of them explained the record type and stopped, so
  # a reader learned what a classroom *is* and not that adding one would fill this list. The other half said
  # only "they appear here", with a pronoun for a noun that was not in the sentence.
  test "every empty state says what will appear here" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(create(:admin, admin: true, classroom: nil))

    [admin_students_path, admin_teachers_path, admin_classrooms_path, admin_school_years_path,
     admin_students_path(discarded: true), admin_teachers_path(discarded: true),
     admin_classrooms_path(discarded: true), admin_users_path(discarded: true)].each do |path|
      visit path
      # The body paragraph only. The title carries no terminal stop, so counting sentences across the
      # whole block merges it with the first one.
      body = page.evaluate_script(<<~JS)
        (function () {
          const s = document.querySelector("[data-testid='empty-state'] p:nth-of-type(2)");
          return s ? s.innerText.replace(/\s+/g, " ").trim() : null;
        })()
      JS
      next if body.nil?

      assert_match(
        /appears? here/, body,
        "#{path}: #{body.inspect} never says what will appear here"
      )
      assert_operator body.split(/(?<=[.!?])\s/).size, :>=, 2,
                      "#{path}: #{body.inspect} - an empty state body is what the thing is, then what " \
                      "appears here"
    end
  end

  # **An empty state explains; the page header acts.**
  #
  # Four admin indexes and the classroom roster carried a filled "New teacher" / "New student" inside the
  # empty state while the page header carried the same button to the same path - two primaries, one
  # destination, which is the fault `one_primary_test` exists for and which this pair slipped past because
  # only one of them renders at a time in a populated database.
  #
  # The header's copy is the one that stays, because it is in the same place whether the list has nothing in
  # it or a hundred rows. An empty state whose action moves to the header when the first record lands is a
  # control that changes position on a state the reader did not choose.
  test "no empty state carries a filled primary" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(create(:admin))

    [admin_teachers_path, admin_students_path, admin_classrooms_path, admin_school_years_path,
     admin_users_path, admin_schools_path, admin_stocks_path, admin_announcements_path].each do |path|
      visit path

      offenders = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll("[data-testid='empty-state'] .tw-btn-primary"))
             .map(function (el) { return el.textContent.trim(); })
      JS

      assert_empty offenders,
                   "#{path}: the empty state renders #{offenders.inspect} as a filled primary. An empty " \
                   "state explains why the list is empty; the page header carries the action."
    end
  end

  test "a teacher's empty classroom" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    visit classroom_path(classroom)

    # The teacher's roster says something different from the admin's, and should: this one can act.
    # The acting is the page header's "Add student" - the empty state used to carry a second filled button
    # to the same place, and now explains instead.
    assert_text "No students yet"
    assert_link "Add student"
    assert_no_text "Add the first student"
    capture("classroom-roster")
  end

  test "a student with nothing yet" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    sign_in student

    visit user_portfolio_path(student, student.portfolio)

    assert_text "Nothing earned yet"
    capture("portfolio")

    visit orders_path
    capture("orders")
  end
end
