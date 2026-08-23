# frozen_string_literal: true

require "test_helper"

module Admin
  class TeachersControllerTest < ActionDispatch::IntegrationTest
    test "index" do
      teacher1 = create(:teacher, email: "z@example.com")
      teacher2 = create(:teacher, email: "a@example.com")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_teachers_path
      rows = css_select("tbody tr[id^='teacher_']")
      row_ids = rows.pluck("id")

      assert_response :success
      assert_select "h1", "Teachers"
      assert_equal [dom_id(teacher2), dom_id(teacher1)], row_ids
    end

    test "index sorts by username by default" do
      create(:teacher, email: "teacher1@example.com")
      create(:teacher, email: "teacher2@example.com")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_teachers_path

      assert_response :success
      # Default sort should be by username ascending (username == email for teachers)
      assert_select "tbody tr:nth-child(1)", text: /teacher1/
      assert_select "tbody tr:nth-child(2)", text: /teacher2/
    end

    test "index shows only active teachers by default" do
      teacher1 = create(:teacher, username: "teacher1")
      teacher2 = create(:teacher, username: "teacher2")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      teacher1.discard

      get admin_teachers_path

      assert_response :success
      assert_select "tbody tr", count: 1
      # The row that is *there*, not a badge. These asserted "Active" on this tab, and the Status column no
      # longer renders here: every row on a filtered tab carries the same value, so the column said nothing
      # and the tab already said it. Naming the surviving teacher is what this test was always about.
      #
      # `display_name`, not the username passed to the factory: `sync_username_from_email` overwrites the
      # username with the email on every save, so the literal never reaches the page.
      assert_select "tbody", text: /#{teacher2.display_name}/
      assert_select "tbody", { text: /#{teacher1.display_name}/, count: 0 }
    end

    test "index shows both active and deactivated teachers with all filter" do
      teacher1 = create(:teacher, username: "teacher1")
      create(:teacher, username: "teacher2")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      teacher1.discard

      get admin_teachers_path(all: true)

      assert_response :success
      assert_select "tbody tr", count: 2
      assert_select "tbody span", text: "Deactivated"
      assert_select "tbody span", text: "Active"
    end

    test "index shows only deactivated teachers with discarded filter" do
      teacher1 = create(:teacher, username: "teacher1")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      teacher1.discard

      get admin_teachers_path(discarded: true)

      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "tbody", text: /#{teacher1.display_name}/
    end

    # Show tests
    test "should show teacher" do
      teacher = create(:teacher)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_teacher_path(teacher)

      assert_response :success
      # The record's own name: `display_name` where the teacher has one, the username otherwise.
      assert_select "h1", teacher.display_name.presence || teacher.username
    end

    test "should show teacher classrooms" do
      # In the **current** school year, because that is the only scope the form offers - `set_form_data`
      # narrows to `Year.current_school_year`. A classroom outside it is not a checkbox on this page, so a
      # fixture in any other year would have asserted against a control that was never going to exist.
      current_year = Year.current_school_year.first_or_create!
      school_year = create(:school_year, school: create(:school), year: current_year)
      classroom = create(:classroom, name: "Math 101", archived: false, school_year:)
      teacher = create(:teacher)
      teacher.classrooms << classroom
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_teacher_path(teacher)

      assert_response :success
      # **No "Classrooms" card.** The form's `classroom_ids` group *is* which classrooms this teacher teaches,
      # and a read-only copy beside it was the same fact twice - once changeable, once not. The count is in the
      # summary line; which ones are ticked in the form.
      assert_select "h2", text: "Classrooms", count: 0
      assert_select "p", text: /1 classroom/
      assert_select "label", text: /#{classroom.name}/
    end

    test "show when teacher has no classrooms" do
      teacher = create(:teacher)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_teacher_path(teacher)

      assert_response :success
      assert_select "p", text: /0 classrooms/
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_teacher_path

      assert_response :success
      assert_select "h1", "New teacher"
    end

    test "new shows warning message when no classrooms available" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_teacher_path

      assert_response :success
      assert_select "h1", "New teacher"

      # The notice is components/ui/_callout now, so its title is a <p> rather than an <h3> - it is
      # a message in a form, not a section heading - and the link is the callout's trailing action
      # rather than a link buried mid-sentence.
      assert_select "[role='status']", text: /No classrooms available/
      # No longer "associated with this school", because there is no school filter to be associated with.
      assert_select "[role='status']", text: /set up for the current school year/
      assert_select "a[href='#{admin_classrooms_path}']", text: /Update classrooms/
    end

    test "new shows classrooms when available" do
      current_year = Year.current_school_year.first_or_create!
      school = create(:school, name: "Test School")
      school_year = create(:school_year, school: school, year: current_year)

      create(:classroom, name: "Test Classroom", archived: false, school_year: school_year)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_teacher_path

      assert_response :success

      assert_select "input[type='checkbox'][name='teacher[classroom_ids][]']"
      # The label is two lines now - the classroom over its school - so the name is a span within it rather
      # than the label's whole text.
      assert_select "label span", text: "Test Classroom"
      assert_select "label span", text: "Test School"

      assert_select "h3", text: "No classrooms available", count: 0
    end

    test "create" do
      classroom1 = create(:classroom, name: "Ice Kingdom")
      classroom2 = create(:classroom, name: "Candy Kingdom")
      params = {
        teacher: {
          username: "lsp",
          email: "lsp@lumpyspace.com",
          name: "Lumpy Space Princess",
          classroom_ids: [classroom1.id, classroom2.id]
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("Teacher.count") do
        post(admin_teachers_path, params:)
      end

      teacher = Teacher.last
      assert_redirected_to admin_teacher_path(teacher)
      assert_equal(
        "Teacher created successfully. Password reset email has been sent.",
        flash[:notice]
      )
      assert_equal [classroom1, classroom2], teacher.classrooms
      assert_not_nil teacher.reset_password_token
    end

    test "create with invalid params" do
      params = {
        teacher: {
          username: "",
          email: "invalid"
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Teacher.count") do
        post(admin_teachers_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      teacher = create(:teacher)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_teacher_path(teacher)

      assert_response :success
      # The record's page edits in place, so its heading is the record's name.
      assert_select "h1", teacher.display_name.presence || teacher.username
    end

    test "update" do
      name = "Lumpy Space Princess"
      classroom1 = create(:classroom, name: "Ice Kingdom")
      classroom2 = create(:classroom, name: "Candy Kingdom")
      teacher = create(:teacher, classrooms: [classroom1])
      params = { teacher: { name:, classroom_ids: [classroom2.id] } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_teacher_path(teacher), params:)
      teacher.reload

      assert_redirected_to admin_teacher_path(teacher)
      assert_equal "Teacher updated successfully.", flash[:notice]
      assert_equal name, teacher.name
      assert_equal [classroom2], teacher.classrooms
    end

    test "update with invalid params" do
      teacher = create(:teacher)
      params = { teacher: { email: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_teacher_path(teacher), params:)

      assert_response :unprocessable_content
    end

    # Hard delete (destroy) tests
    test "should permanently delete deactivated teacher" do
      teacher = create(:teacher, email: "teacher1@example.com")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      teacher.discard

      assert_difference("Teacher.with_discarded.count", -1) do
        delete admin_teacher_path(teacher)
      end

      assert_redirected_to admin_teachers_path
      assert_equal "Teacher teacher1@example.com permanently deleted.", flash[:notice]
      assert_nil Teacher.with_discarded.find_by(id: teacher.id)
    end

    test "should not permanently delete active teacher" do
      teacher = create(:teacher, username: "teacher1")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Teacher.with_discarded.count") do
        delete admin_teacher_path(teacher)
      end

      assert_redirected_to edit_admin_teacher_path(teacher)
      assert_equal "Teacher must be deactivated before permanent deletion.", flash[:alert]
      assert_not teacher.reload.discarded?
    end

    test "permanent delete should remove teacher from database and DOM" do
      teacher = create(:teacher, username: "teacher1")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      teacher.discard

      assert_difference("Teacher.with_discarded.count", -1) do
        delete admin_teacher_path(teacher)
      end

      follow_redirect!

      assert_select "##{dom_id(teacher)}", count: 0
    end

    # **A teacher can hold classrooms in more than one school**, and this form used to guarantee they could
    # not. The checkbox group is the whole of `classroom_ids`, a school filter narrowed the list to one
    # school, and `update` assigns what was submitted - so the other school's classroom was removed. It
    # needed no interaction: the filter defaulted to the school of the teacher's *first* classroom, so
    # opening the page and pressing Update was enough. Measured in a console: "A room, B room" in, "A room"
    # out.
    #
    # The filter is gone and the group lists every current-year classroom, so nothing can be hidden from the
    # submit. These two stay as the regression: one that both classrooms are on the page, one that a save
    # keeps them. They no longer pass `?school_id=`, which nothing reads - a test that sends a param the app
    # ignores reads as coverage of a filter that does not exist.
    test "the form lists every classroom a teacher holds, across schools" do
      teacher, _first_school, other_room = a_teacher_in_two_schools

      get edit_admin_teacher_path(teacher)

      assert_response :success
      assert_select "input[type=checkbox][value=?][checked]", other_room.id.to_s, { count: 1 },
                    "the classroom in the other school is not on the list, so saving would drop it"
    end

    test "saving keeps a classroom in the other school" do
      teacher, _first_school, other_room = a_teacher_in_two_schools

      get edit_admin_teacher_path(teacher)
      ids = response.parsed_body.css("input[type=checkbox][checked]").pluck("value")

      patch admin_teacher_path(teacher), params: { teacher: { classroom_ids: ids } }

      assert_redirected_to admin_teacher_path(teacher)
      assert_includes teacher.reload.classroom_ids, other_room.id,
                      "the other school's classroom was dropped by a save that never mentioned it"
    end

    # The row names the school, because nothing above the list does any more and two schools can each run a
    # classroom of the same name.
    test "each classroom option names its school" do
      teacher, first_school, = a_teacher_in_two_schools

      get edit_admin_teacher_path(teacher)

      assert_response :success
      assert_select "fieldset label span", text: first_school.name, count: 1
    end

    def a_teacher_in_two_schools
      year = Year.current_school_year.first_or_create!(name: Year.current_school_year_name)
      grade = create(:grade)
      first_school = create(:school)
      other_school = create(:school)
      first_room = create(:classroom, school_year: create(:school_year, school: first_school, year:), grades: [grade])
      other_room = create(:classroom, school_year: create(:school_year, school: other_school, year:), grades: [grade])
      teacher = create(:teacher)
      teacher.classrooms = [first_room, other_room]
      sign_in(create(:admin, admin: true, classroom: nil))

      [teacher, first_school, other_room]
    end
  end
end
