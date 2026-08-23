# frozen_string_literal: true

require "test_helper"

# A teacher may edit the classroom they teach, and the parameter filter - not the form - is what stops
# that becoming more than it should be. Every request here is one a teacher could craft by hand.
class ClassroomsUpdatePermissionTest < ActionDispatch::IntegrationTest
  setup do
    @classroom = create(:classroom, name: "Original Name")
    @teacher = create(:teacher)
    create(:teacher_classroom, teacher: @teacher, classroom: @classroom)
    @grade_ids = @classroom.grade_ids
  end

  test "a teacher can rename the classroom they teach" do
    sign_in @teacher

    patch classroom_path(@classroom),
          params: { classroom: { name: "Renamed By Teacher", grade_ids: @grade_ids } }

    assert_redirected_to classroom_url(@classroom)
    assert_equal "Renamed By Teacher", @classroom.reload.name
  end

  test "a teacher cannot move the classroom to another school year" do
    other = create(:school_year, school: create(:school), year: create(:year))
    was = @classroom.school_year_id
    sign_in @teacher

    patch classroom_path(@classroom),
          params: { classroom: { name: "Still Mine", grade_ids: @grade_ids,
                                 school_id: other.school_id, year_id: other.year_id } }

    assert_equal was, @classroom.reload.school_year_id,
                 "a teacher moved their classroom to a different school year"
  end

  # The one that matters most: teacher_ids is who may see and edit the classroom.
  test "a teacher cannot change who teaches the classroom" do
    intruder = create(:teacher)
    sign_in @teacher

    patch classroom_path(@classroom),
          params: { classroom: { name: "Still Mine", grade_ids: @grade_ids,
                                 teacher_ids: [intruder.id] } }

    assert_equal [@teacher.id], @classroom.reload.teacher_ids,
                 "a teacher changed the classroom's teacher list"
  end

  test "a teacher cannot remove themselves and orphan the classroom" do
    sign_in @teacher

    patch classroom_path(@classroom),
          params: { classroom: { name: "Still Mine", grade_ids: @grade_ids, teacher_ids: [""] } }

    assert_equal [@teacher.id], @classroom.reload.teacher_ids
  end

  test "a teacher cannot edit a classroom they do not teach" do
    other = create(:classroom, name: "Not Mine")
    sign_in @teacher

    patch classroom_path(other),
          params: { classroom: { name: "Hijacked", grade_ids: other.grade_ids } }

    assert_equal "Not Mine", other.reload.name
  end

  test "an admin can still move the classroom and set its teachers" do
    other = create(:school_year, school: create(:school), year: create(:year))
    replacement = create(:teacher)
    sign_in create(:admin)

    patch classroom_path(@classroom),
          params: { classroom: { name: "Moved By Admin", grade_ids: @grade_ids,
                                 school_id: other.school_id, year_id: other.year_id,
                                 teacher_ids: [replacement.id] } }

    @classroom.reload

    assert_equal "Moved By Admin", @classroom.name
    assert_equal other.id, @classroom.school_year_id
    assert_equal [replacement.id], @classroom.teacher_ids
  end
end
