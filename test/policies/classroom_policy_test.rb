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
    assert_permit admin, classroom, :destroy
  end

  test "classroom policy allows teacher only `index` and `show` classroom routes" do
    classroom = create(:classroom)
    teacher = create(:teacher)

    assert_permit teacher, classroom, :index
    assert_permit teacher, classroom, :show
    refute_permit teacher, classroom, :new
    refute_permit teacher, classroom, :create
    refute_permit teacher, classroom, :edit
    refute_permit teacher, classroom, :update
    refute_permit teacher, classroom, :destroy
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
    refute_permit student, classroom, :destroy
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
