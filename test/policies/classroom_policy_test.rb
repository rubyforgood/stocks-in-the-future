# frozen_string_literal: true

require "test_helper"

class ClassroomPolicyTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:classroom).validate!
  end

  test "classroom policy allows admin all the class routes" do
    classroom = create(:classroom)
    admin = create(:admin)

    assert_permit admin, classroom, :index
    assert_permit admin, classroom, :show
    assert_permit admin, classroom, :new
    assert_permit admin, classroom, :create
    assert_permit admin, classroom, :edit
    assert_permit admin, classroom, :update
    assert_permit admin, classroom, :toggle_archive
  end

  # A classroom this teacher does not teach. Editing is per classroom, not per role, so the same
  # teacher gets a different answer in the test below.
  test "classroom policy allows teacher only `index` and `show` on someone else's classroom" do
    classroom = create(:classroom)
    teacher = create(:teacher)

    assert_permit teacher, classroom, :index
    assert_permit teacher, classroom, :show
    refute_permit teacher, classroom, :new
    refute_permit teacher, classroom, :create
    refute_permit teacher, classroom, :edit
    refute_permit teacher, classroom, :update
    refute_permit teacher, classroom, :toggle_archive
  end

  test "classroom policy lets a teacher edit a classroom they teach" do
    classroom = create(:classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)

    assert_permit teacher, classroom, :edit
    assert_permit teacher, classroom, :update
    assert_permit teacher, classroom, :toggle_trading

    # Editing their own classroom is not a route into the administrative ones.
    refute_permit teacher, classroom, :new
    refute_permit teacher, classroom, :create
    refute_permit teacher, classroom, :toggle_archive
  end

  # The narrower half of the grant. A teacher may rename their classroom and set how it is taught;
  # school, year and the teacher assignment are administrative, and teacher_ids in particular is who
  # may see and edit the classroom at all.
  test "a teacher may not change the school, the year or who teaches the classroom" do
    classroom = create(:classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)

    permitted = ClassroomPolicy.new(teacher, classroom).permitted_attributes

    assert_includes permitted, :name
    assert_includes permitted, :trading_enabled
    assert_includes permitted, { grade_ids: [] }
    assert_not_includes permitted, :school_id
    assert_not_includes permitted, :year_id
    assert_not_includes permitted, { teacher_ids: [] }
  end

  test "an admin may change all of them" do
    permitted = ClassroomPolicy.new(create(:admin), create(:classroom)).permitted_attributes

    assert_includes permitted, :school_id
    assert_includes permitted, :year_id
    assert_includes permitted, { teacher_ids: [] }
  end

  # A policy can be built around the class rather than a record - `policy(Classroom).new?` in the
  # index view - and the teacher check reads record.id.
  test "the teacher check refuses a class rather than raising" do
    refute_permit create(:teacher), Classroom, :edit
  end

  test "classroom policy does not allow student any classroom routes" do
    classroom = create(:classroom)
    student = create(:student)

    refute_permit student, classroom, :index
    refute_permit student, classroom, :show
    refute_permit student, classroom, :new
    refute_permit student, classroom, :create
    refute_permit student, classroom, :edit
    refute_permit student, classroom, :update
    refute_permit student, classroom, :toggle_archive
  end

  test "classroom policy allows admins access to all the classrooms" do
    admin = create(:admin)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    scope = ClassroomPolicy::Scope.new(admin, Classroom.all).resolve

    assert_includes scope, classroom1
    assert_includes scope, classroom2
  end

  test "classroom policy allows teachers access to their own classrooms only" do
    teacher = create(:teacher)
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)
    teacher.classrooms << classroom1

    scope = ClassroomPolicy::Scope.new(teacher, Classroom.all).resolve

    assert_includes scope, classroom1
    assert_not_includes scope, classroom2
  end
end
