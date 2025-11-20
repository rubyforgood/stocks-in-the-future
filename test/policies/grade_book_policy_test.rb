# frozen_string_literal: true

require "test_helper"

class GradeBookPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin)
    @owner_teacher = create(:teacher)
    @other_teacher = create(:teacher)
    @student = create(:student)

    @classroom = create(:classroom)
    @classroom.teachers << @owner_teacher

    @grade_book = create(:grade_book, classroom: @classroom)
  end

  test "show? allows admin and owner teacher, denies others" do
    assert_permit @admin, @grade_book, :show
    assert_permit @owner_teacher, @grade_book, :show
    refute_permit @other_teacher, @grade_book, :show
    refute_permit @student, @grade_book, :show
  end

  test "update? allows admin and owner teacher, denies others" do
    assert_permit @admin, @grade_book, :update
    assert_permit @owner_teacher, @grade_book, :update
    refute_permit @other_teacher, @grade_book, :update
    refute_permit @student, @grade_book, :update
  end

  test "finalize? allows only admin, denies everyone else" do
    assert_permit @admin, @grade_book, :finalize
    refute_permit @owner_teacher, @grade_book, :finalize
    refute_permit @other_teacher, @grade_book, :finalize
    refute_permit @student, @grade_book, :finalize
  end
end
