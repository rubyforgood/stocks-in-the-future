# frozen_string_literal: true

require "test_helper"

class ClassroomsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create(:admin)
    @classroom = create(:classroom)
    @teacher = create(:teacher)
    @teacher.classrooms << @classroom
    @student = create(:student, classroom: @classroom)
  end

  test "index" do
    sign_in(@admin)
    get classrooms_path
    assert_response :success
  end

  test "new" do
    sign_in(@admin)
    get new_classroom_path
    assert_response :success
  end

  test "create" do
    sign_in(@admin)
    school = create(:school)
    year = create(:year)
    params = { classroom: { name: "Test Class", grade: 5, school_id: school.id, year_id: year.id } }
    assert_difference("Classroom.count") do
      post(classrooms_path, params:)
    end
    assert_redirected_to classroom_path(Classroom.last)
    assert_equal t("classrooms.create.notice"), flash[:notice]
  end

  test "show" do
    sign_in(@admin)
    get classroom_path(@classroom)
    assert_response :success
  end

  test "edit" do
    sign_in(@admin)
    get edit_classroom_path(@classroom)
    assert_response :success
  end

  test "update" do
    school = create(:school)
    year = create(:year)
    params = { classroom: { name: "Abc123", grade: 6, school_id: school.id, year_id: year.id } }
    sign_in(@admin)
    assert_changes "@classroom.reload.updated_at" do
      patch(classroom_path(@classroom), params:)
    end
    assert_redirected_to classroom_path(@classroom)
    assert_equal t("classrooms.update.notice"), flash[:notice]
  end

  test "archive classroom" do
    sign_in(@admin)
    assert_no_difference("Classroom.count") do
      patch toggle_archive_admin_classroom_path(@classroom)
    end
    assert_redirected_to admin_classrooms_path
    assert @classroom.reload.archived?
    assert_equal "Classroom has been archived.", flash[:notice]
  end

  test "activate classroom" do
    sign_in(@admin)
    @classroom.update!(archived: true)
    patch toggle_archive_admin_classroom_path(@classroom)
    assert_redirected_to admin_classrooms_path
    assert_not @classroom.reload.archived?
    assert_equal "Classroom has been activated.", flash[:notice]
  end

  test "admins can see all classrooms in index" do
    classroom1 = create(:classroom, name: "Class 1")
    classroom2 = create(:classroom, name: "Class 2")
    sign_in(@admin)
    get classrooms_path
    assert_response :success
    assert_includes response.body, classroom1.name
    assert_includes response.body, classroom2.name
  end

  test "show includes student management for teachers" do
    create(:portfolio, user: @student)
    # @teacher.classrooms << @classroom
    sign_in @teacher
    get classroom_path(@classroom)
    assert_response :success
    assert_includes response.body, @student.username
  end

  test "teachers can only see their own classroom in index" do
    classroom1 = create(:classroom, name: "Teacher 1 Class")
    classroom2 = create(:classroom, name: "Teacher 2 Class")
    teacher = create(:teacher, classroom: classroom1)
    teacher.classrooms << classroom1
    sign_in teacher
    get classrooms_path
    assert_response :success
    assert_includes response.body, classroom1.name
    assert_not_includes response.body, classroom2.name
  end

  test "teachers cannot see archived classrooms in index" do
    classroom1 = create(:classroom, name: "Active Class")
    classroom2 = create(:classroom, name: "Archived Class", archived: true)
    teacher = create(:teacher)
    teacher.classrooms << classroom1
    teacher.classrooms << classroom2
    sign_in teacher
    get classrooms_path
    assert_response :success
    assert_includes response.body, classroom1.name
    assert_not_includes response.body, classroom2.name
  end

  test "teachers can only access details of their own classroom" do
    classroom1 = create(:classroom, name: "Teacher 1 Class")
    classroom2 = create(:classroom, name: "Teacher 2 Class")
    teacher = create(:teacher)
    teacher.classrooms << classroom1
    sign_in teacher

    get classroom_path(classroom1)
    assert_response :success
    assert_includes response.body, classroom1.name

    get classroom_path(classroom2)
    assert_redirected_to root_path
  end

  test "students cannot see classrooms" do
    sign_in @student
    get classrooms_path
    assert_redirected_to @student.portfolio_path
  end

  test "students cannot see details of a classroom" do
    sign_in @student
    classroom1 = create(:classroom, name: "Teacher 1 Class")
    get classroom_path(id: classroom1.id)
    assert_redirected_to @student.portfolio_path
  end

  test "students cannot create or edit classrooms" do
    sign_in @student

    get new_classroom_path
    assert_redirected_to @student.portfolio_path

    get edit_classroom_path(@classroom)
    assert_redirected_to @student.portfolio_path
  end

  test "teachers cannot create classrooms" do
    sign_in @teacher
    get new_classroom_path
    assert_redirected_to root_path
  end

  test "teachers can toggle trading for their own classrooms" do
    sign_in @teacher
    assert_not @classroom.trading_enabled
    patch toggle_trading_classroom_path(@classroom)
    assert_redirected_to classroom_path(@classroom)
    assert @classroom.reload.trading_enabled
  end

  test "teachers cannot edit classrooms" do
    sign_in @teacher
    get edit_classroom_path(@classroom)
    assert_redirected_to root_path
  end

  test "teachers cannot toggle trading for other teachers' classrooms" do
    other_classroom = create(:classroom, name: "Other Class")
    sign_in @teacher
    patch toggle_trading_classroom_path(other_classroom)
    assert_redirected_to root_path
  end

  test "teachers cannot archive classrooms" do
    sign_in @teacher
    # Teachers shouldn't be able to archive
    patch toggle_archive_admin_classroom_path(@classroom)
    assert_redirected_to root_path
  end

  # Tests for dropdown functionality
  test "new action renders form with school and year dropdowns" do
    school1 = create(:school, name: "Elementary School")
    school2 = create(:school, name: "High School")
    year1 = create(:year, name: "2023-2024")
    year2 = create(:year, name: "2024-2025")

    sign_in(@admin)
    get new_classroom_path

    assert_response :success
    assert_select "select[name='classroom[school_id]']" do
      assert_select "option[value='#{school1.id}']", text: school1.name
      assert_select "option[value='#{school2.id}']", text: school2.name
    end
    assert_select "select[name='classroom[year_id]']" do
      assert_select "option[value='#{year1.id}']", text: year1.name
      assert_select "option[value='#{year2.id}']", text: year2.name
    end
  end

  test "edit action renders form with school and year dropdowns" do
    school1 = create(:school, name: "Elementary School")
    school2 = create(:school, name: "High School")
    year1 = create(:year, name: "2023-2024")
    year2 = create(:year, name: "2024-2025")

    sign_in(@admin)
    get edit_classroom_path(@classroom)

    assert_response :success
    assert_select "select[name='classroom[school_id]']" do
      assert_select "option[value='#{school1.id}']", text: school1.name
      assert_select "option[value='#{school2.id}']", text: school2.name
    end
    assert_select "select[name='classroom[year_id]']" do
      assert_select "option[value='#{year1.id}']", text: year1.name
      assert_select "option[value='#{year2.id}']", text: year2.name
    end
  end

  test "create with valid school_id and year_id creates classroom with correct school_year" do
    school = create(:school, name: "Test School")
    year = create(:year, name: "2024-2025")

    sign_in(@admin)
    params = { classroom: { name: "Test Class", grade: 5, school_id: school.id, year_id: year.id } }

    assert_difference("Classroom.count") do
      post(classrooms_path, params:)
    end

    classroom = Classroom.last
    assert_equal school, classroom.school
    assert_equal year, classroom.year
  end

  test "update with valid school_id and year_id updates classroom school_year" do
    new_school = create(:school, name: "New School")
    new_year = create(:year, name: "2025-2026")

    sign_in(@admin)
    params = { classroom: { name: "Updated Class", school_id: new_school.id, year_id: new_year.id } }

    patch(classroom_path(@classroom), params:)

    @classroom.reload
    assert_equal new_school, @classroom.school
    assert_equal new_year, @classroom.year
  end

  test "edit form shows current school and year selected" do
    school = create(:school, name: "Current School")
    year = create(:year, name: "Current Year")
    school_year = create(:school_year, school: school, year: year)
    classroom = create(:classroom, school_year: school_year)

    sign_in(@admin)
    get edit_classroom_path(classroom)

    assert_response :success
    assert_select "select[name='classroom[school_id]']" do
      assert_select "option[value='#{school.id}'][selected='selected']", text: school.name
    end
    assert_select "select[name='classroom[year_id]']" do
      assert_select "option[value='#{year.id}'][selected='selected']", text: year.name
    end
  end

  test "index page includes link to classroom show page" do
    sign_in(@admin)
    classroom = create(:classroom, name: "Linked Class")

    get classrooms_path
    assert_response :success
    assert_select "a[href='#{classroom_path(classroom)}']", text: "Linked Class"
  end
end
