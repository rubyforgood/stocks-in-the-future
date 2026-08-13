# frozen_string_literal: true

require "test_helper"

module Admin
  class ClassroomsControllerTest < ActionDispatch::IntegrationTest
    test "index" do
      classroom1 = create(:classroom, name: "Bravo")
      classroom2 = create(:classroom, name: "Charlie")
      classroom3 = create(:classroom, name: "Alpha")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_classrooms_path
      rows = css_select("tbody tr[id^='classroom_']")
      ordered_row_ids = rows.pluck("id")

      assert_response :success
      assert_select "h1", "Classrooms"
      assert_equal(
        [dom_id(classroom3), dom_id(classroom1), dom_id(classroom2)],
        ordered_row_ids
      )
    end

    # The three archive tabs, which this index did not have: it listed archived classrooms among the live
    # ones with only the Status column telling them apart, and sorting by Archived - the old way to group
    # them - went when two badge columns became one.
    #
    # `Classroom` archives with a boolean rather than `discard`, so these assert the mapping onto its own
    # scopes as well as the param reading in `SoftDeletableFiltering#discard_filter`.
    test "index lists only active classrooms by default" do
      active = create(:classroom, name: "Active room")
      archived = create(:classroom, name: "Archived room", archived: true)
      sign_in(create(:admin, admin: true, classroom: nil))

      get admin_classrooms_path

      assert_response :success
      assert_select "tbody tr##{dom_id(active)}", count: 1
      assert_select "tbody tr##{dom_id(archived)}", count: 0
    end

    test "index with the archived filter lists only archived classrooms" do
      active = create(:classroom, name: "Active room")
      archived = create(:classroom, name: "Archived room", archived: true)
      sign_in(create(:admin, admin: true, classroom: nil))

      get admin_classrooms_path(discarded: true)

      assert_response :success
      assert_select "tbody tr##{dom_id(archived)}", count: 1
      assert_select "tbody tr##{dom_id(active)}", count: 0
      assert_select "[data-testid='filter-tabs'] a[aria-current='page']", text: "Archived"
    end

    test "index with the all filter lists both" do
      active = create(:classroom, name: "Active room")
      archived = create(:classroom, name: "Archived room", archived: true)
      sign_in(create(:admin, admin: true, classroom: nil))

      get admin_classrooms_path(all: true)

      assert_response :success
      assert_select "tbody tr##{dom_id(active)}", count: 1
      assert_select "tbody tr##{dom_id(archived)}", count: 1
    end

    # An empty Archived tab is a different sentence from an empty index: there are classrooms, none of them
    # archived, and the New button that belongs on the other branch would not put one in this list.
    test "index with the archived filter and nothing archived says so" do
      create(:classroom, name: "Active room")
      sign_in(create(:admin, admin: true, classroom: nil))

      get admin_classrooms_path(discarded: true)

      assert_response :success
      assert_select "[data-testid='empty-state']", text: /No archived classrooms/
      assert_select "[data-testid='empty-state'] a", text: "New classroom", count: 0
    end

    test "show" do
      grade9 = create(:grade, level: 9)
      grade10 = create(:grade, level: 10)
      classroom = create(:classroom, grades: [grade9, grade10])
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_classroom_path(classroom)

      assert_response :success
      assert_select "h1", classroom.name
      # The grades are a **form field** now, not a read-only row: the form edits `grade_ids`, so a definition
      # list of them beside the checkboxes was the same fact twice. The summary line carries the display value.
      assert_select "[data-testid='grades_display'] dd", count: 0
      assert_select "p", text: /9th-10th/
    end

    test "should get new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_classroom_path

      assert_response :success
      assert_select "h1", "New classroom"
    end

    test "create" do
      grade = create(:grade, level: 7)
      school_year = create(:school_year)
      # `school_id` and `year_id`, which is what the form posts: they are fields, not columns, and the
      # pair is found-or-created into a SchoolYear. This posted `school_year_id`, which the admin
      # controller used to permit and the form never sent - a test agreeing with the controller rather
      # than with the browser.
      params = {
        classroom: {
          name: "Abc123",
          grade_ids: [grade.id],
          school_id: school_year.school_id,
          year_id: school_year.year_id
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("Classroom.count") do
        post(admin_classrooms_path, params:)
      end

      assert_redirected_to admin_classroom_path(Classroom.last)
      assert_equal "Classroom created successfully.", flash[:notice]
    end

    test "create with invalid params" do
      params = { classroom: { name: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Classroom.count") do
        post(admin_classrooms_path, params:)
      end

      assert_response :unprocessable_entity
    end

    test "edit" do
      classroom = create(:classroom)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_classroom_path(classroom)

      assert_response :success
      # The record's page edits in place, so its heading is the record's name.
      assert_select "h1", classroom.name
    end

    test "update" do
      name = "Abc123"
      classroom = create(:classroom)
      params = { classroom: { name: } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_classroom_path(classroom), params:)

      # The record, which is right after an *update*: you have just edited this thing and the show page is
      # where you see the result. Only the row actions return you to the list.
      assert_redirected_to admin_classroom_path(classroom)
      assert_equal "Classroom updated successfully.", flash[:notice]
      assert_equal name, classroom.reload.name
    end

    test "update with invalid params" do
      classroom = create(:classroom)
      params = { classroom: { name: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_classroom_path(classroom), params:)

      assert_response :unprocessable_entity
    end

    test "toggle_archive" do
      classroom = create(:classroom, archived: false)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch toggle_archive_admin_classroom_path(classroom)
      classroom.reload

      # The list, not the record. Archiving is a row action on the index, and being moved to a page you
      # did not ask for is the cost of one click on a row. With no Referer this is the fallback; the
      # test below covers the case where there is one.
      assert_redirected_to admin_classrooms_path
      assert_equal "Classroom has been archived.", flash[:notice]
      assert classroom.archived?
    end

    test "activate via toggle_archive" do
      classroom = create(:classroom, archived: true)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch toggle_archive_admin_classroom_path(classroom)
      classroom.reload

      # The list, not the record. Archiving is a row action on the index, and being moved to a page you
      # did not ask for is the cost of one click on a row. With no Referer this is the fallback; the
      # test below covers the case where there is one.
      assert_redirected_to admin_classrooms_path
      assert_equal "Classroom has been activated.", flash[:notice]
      assert_not classroom.archived?
    end

    # `redirect_back_or_to`, so archiving from the classroom's own page stays there and shows the new
    # state. Without this test the fallback would pass while the referer branch was never exercised - the
    # same shape as a negative test that passes because the endpoint is broken.
    test "toggle_archive returns to the page it was called from" do
      classroom = create(:classroom)
      sign_in(create(:admin, admin: true, classroom: nil))

      patch toggle_archive_admin_classroom_path(classroom),
            headers: { "HTTP_REFERER" => admin_classroom_url(classroom) }

      assert_redirected_to admin_classroom_url(classroom)
    end

    test "index when teacher" do
      teacher = create(:teacher)
      sign_in(teacher)

      get admin_classrooms_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "toggle archive when teacher" do
      classroom = create(:classroom)
      teacher = create(:teacher)
      sign_in(teacher)

      patch toggle_archive_admin_classroom_path(classroom)

      assert_redirected_to root_path
    end
  end
end
