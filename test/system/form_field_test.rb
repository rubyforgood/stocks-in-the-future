# frozen_string_literal: true

require "application_system_test_case"

# One field shape across every form in the app.
#
# There were seven. `Ui::FormBuilder` backed nine forms with `rounded-md`, a border faked from
# `ring-1 ring-inset ring-gray-300`, an off-brand `blue-600` focus ring, an `sm:` tier this app does
# not use, and **`placeholder:text-gray-400` at 2.54:1** - a straight AA failure on every placeholder
# it rendered. The grade book's selects focused `indigo-500`. The two student forms, the admin search
# filter and two devise pages each wrote their own. `tw-input-primary` existed the whole time and one
# view used it.
#
# The subtle one: passing `tw-input-primary` to the old shadcn builder looked like it worked and did
# not. That builder prepends its own shadcn base, so the field carried both strings - and because
# utilities beat component classes, the shadcn ones won. Sign in and sign up, the two pages every
# user sees first, kept a 40px `rounded-md` field while everything else moved.
class FormFieldTest < ApplicationSystemTestCase
  BORDER = "1px"
  RADIUS = "8px" # rounded-lg, the control token
  # slate-500, raised from slate-300 for WCAG 1.4.11: a text input's boundary is the only thing identifying
  # it on a white card, and slate-300 measured **1.49:1** where the criterion asks for 3:1. slate-400 is
  # 2.63:1 and still fails, so slate-500 - 4.76:1 - is the first token that clears it.
  SLATE_500 = "oklch(0.554 0.046 257.417)"
  TOUCH_HEIGHT = 44 # min-h-11

  def field_shapes
    page.evaluate_script(<<~JS)
      (function () {
        const out = [];
        const seen = new Set();
        // Radios are excluded for the same reason checkboxes are: neither is a box-shaped field, so
        // the border/radius/height tokens do not apply to them. The grade book's perfect-attendance
        // control is two `sr-only` radios with styled labels - a native segmented control - and an
        // sr-only input is not a rendered field at all, which the 1x1 box below also catches.
        document.querySelectorAll(
          "input:not([type=hidden]):not([type=submit]):not([type=checkbox]):not([type=radio]), select, textarea"
        ).forEach(el => {
          const s = getComputedStyle(el);
          const b = el.getBoundingClientRect();
          if (!b.height) return;
          if (b.width <= 1 && b.height <= 1) return;
          const key = [s.borderTopWidth, s.borderTopLeftRadius, s.fontSize,
                       s.borderTopColor, el.tagName].join("|");
          if (seen.has(key)) return;
          seen.add(key);
          out.push({
            tag: el.tagName.toLowerCase(),
            border: s.borderTopWidth,
            radius: s.borderTopLeftRadius,
            colour: s.borderTopColor,
            height: Math.round(b.height)
          });
        });
        return out;
      })()
    JS
  end

  def assert_fields_on_token(label)
    shapes = field_shapes

    assert_not_empty shapes, "#{label}: no fields found"

    shapes.each do |f|
      assert_equal BORDER, f["border"], "#{label}: a #{f['tag']} is not on a 1px border"
      assert_equal RADIUS, f["radius"],
                   "#{label}: a #{f['tag']} is #{f['radius']}, not rounded-lg"
      assert_equal SLATE_500, f["colour"],
                   "#{label}: a #{f['tag']}'s border is not slate-500, which is what 1.4.11 needs"
      # A textarea is taller by rows; everything else sits on the touch minimum.
      next if f["tag"] == "textarea"

      assert_operator f["height"], :>=, TOUCH_HEIGHT - 1,
                      "#{label}: a #{f['tag']} is #{f['height']}px, under the 44px minimum"
    end
  end

  # The two pages every user meets first, and the ones the shadcn builder silently kept off the token.
  test "the auth pages are on the token" do
    visit new_user_session_path
    assert_fields_on_token("sign in")

    visit new_user_password_path
    assert_fields_on_token("reset password")
  end

  test "the admin forms are on the token" do
    school = create(:school)
    create(:school_year, school:, year: create(:year))
    sign_in(create(:admin))

    { "student new" => "/admin/students/new",
      "stock new" => "/admin/stocks/new",
      "user new" => "/admin/users/new",
      "classroom new" => "/admin/classrooms/new" }.each do |label, path|
      visit path
      assert_fields_on_token(label)
    end
  end

  test "the teacher forms are on the token" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    grade_book = classroom.grade_books.first || create(:grade_book, classroom:)
    create(:grade_entry, grade_book:, user: student)
    sign_in(teacher)

    visit classroom_grade_book_path(classroom, grade_book)
    assert_fields_on_token("grade book")

    visit new_classroom_student_path(classroom)
    assert_fields_on_token("new student")
  end

  # The placeholder was the AA failure, and it was on every admin form.
  # **One width for every single-line control; the full measure only for a textarea.**
  #
  # Reported: the inputs on the create and edit pages did not match the new classroom page, and some selects
  # were one column while others were two. Measured, and they were right - the *same field* had two widths on
  # two pages. School and Year were 351px on `admin/classrooms` and **726px** on `admin/school_years`;
  # Classroom was 726 on students and users while Transaction type beside it on transactions was 351.
  #
  # `width: :half` is opt-in and the default is `:full` - deliberately, so a field nobody has considered
  # keeps what it has - which is why the original sweep left nine behind. This is the check that opt-in
  # needed: a form card's single-line controls all measure the one-column width, and anything that does not
  # has to be a textarea.
  HALF = 351
  FULL = 726

  test "every single-line field in a form card is one column wide" do
    classroom = create(:classroom, :with_trading)
    create(:student, classroom:)
    create(:stock)
    create(:school)
    sign_in(create(:admin))

    { "teachers" => new_admin_teacher_path, "students" => new_admin_student_path,
      "schools" => new_admin_school_path, "stocks" => new_admin_stock_path,
      "classrooms" => new_admin_classroom_path, "school years" => new_admin_school_year_path,
      "announcements" => new_admin_announcement_path, "users" => new_admin_user_path,
      "transactions" => new_admin_portfolio_transaction_path,
      "app classrooms" => new_classroom_path,
      "app students" => new_classroom_student_path(classroom) }.each do |name, path|
      visit path

      page.evaluate_script(<<~JS).each do |field|
        Array.from(document.querySelectorAll("main .tw-card input, main .tw-card select, main .tw-card textarea"))
             .filter(function (el) {
               return el.type !== "hidden" && el.type !== "checkbox" && el.getClientRects().length > 0;
             })
             .map(function (el) {
               const label = el.labels && el.labels[0] ? el.labels[0].textContent.trim() : el.name;
               return { tag: el.tagName.toLowerCase(), type: el.type, label: label,
                        width: Math.round(el.getBoundingClientRect().width) };
             })
      JS
        # A textarea and a URL keep the full measure, and both are readable from the element - the URL by
        # its `type`, not by a name in a list. An exception the test can see cannot rot the way a named one
        # does.
        full = field["tag"] == "textarea" || field["type"] == "url"
        want = full ? FULL : HALF
        assert_in_delta want, field["width"], 2,
                        "#{name}: #{field['tag']} \"#{field['label']}\" is #{field['width']}px, and a " \
                        "#{field['tag']} is #{want}. A field with two widths across two pages is what this " \
                        "catches; `width: :half` is opt-in, so a new one starts full."
      end
    end
  end

  test "placeholders are readable" do
    sign_in(create(:admin))
    visit "/admin/stocks/new"

    failures = page.evaluate_script(<<~JS)
      (function () {
        const ctx = document.createElement("canvas").getContext("2d");
        function lum(c) {
          ctx.clearRect(0, 0, 1, 1);
          ctx.fillStyle = c;
          ctx.fillRect(0, 0, 1, 1);
          const d = ctx.getImageData(0, 0, 1, 1).data;
          const f = [d[0], d[1], d[2]].map(v => {
            v /= 255;
            return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
          });
          return 0.2126 * f[0] + 0.7152 * f[1] + 0.0722 * f[2];
        }
        const out = [];
        document.querySelectorAll("input[placeholder], textarea[placeholder]").forEach(el => {
          const c = getComputedStyle(el, "::placeholder").color;
          const bg = getComputedStyle(el).backgroundColor;
          const l1 = lum(c), l2 = lum(bg === "rgba(0, 0, 0, 0)" ? "rgb(255,255,255)" : bg);
          const ratio = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
          if (ratio < 4.5) out.push(ratio.toFixed(2) + ":1 - " + el.placeholder);
        });
        return out;
      })()
    JS

    assert_empty failures,
                 "a placeholder is text; gray-400 measured 2.54:1 and shipped on nine admin forms"
  end
  # **A field whose value will be discarded is not left editable.** `Teacher#sync_username_from_email` runs
  # `before_validation` and replaces the username with the email, so a username typed for a teacher on the
  # users form was thrown away on save - measured in a console, "typed_by_hand" came back as the email address.
  # The form accepted it, said nothing, and the record disagreed.
  #
  # Read-only rather than disabled: a disabled field is skipped by keyboard navigation, and the profile page's
  # username records the same decision.
  test "the users form stops offering a username the type will overwrite" do
    sign_in create(:admin)

    visit new_admin_user_path

    read_only = -> { page.evaluate_script('document.getElementById("user_username").readOnly') }

    assert_equal false, read_only.call, "a plain user types their own username"

    select "Teacher", from: "User type"

    assert_equal true, read_only.call, "a teacher's username comes from their email and is still editable"
    assert_no_selector "#user_username:not([readonly])"

    select "Student", from: "User type"

    assert_equal false, read_only.call, "a student types their own username"
  end
end
