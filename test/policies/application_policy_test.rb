# frozen_string_literal: true

require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  test "teacher_or_admin_required?" do
    admin = create(:admin)
    teacher = create(:teacher)
    student = create(:student)
    the_nil = nil

    [admin, teacher].each do |the_user|
      assert ApplicationPolicy.new(the_user, :application).teacher_or_admin_required?
    end

    [student, the_nil].each do |the_user|
      assert_not ApplicationPolicy.new(the_user, :application).teacher_or_admin_required?
    end
  end

  test "admin_required?" do
    admin = create(:admin)
    teacher = create(:teacher)
    student = create(:student)
    the_nil = nil

    assert ApplicationPolicy.new(admin, :application).admin_required?

    [teacher, student, the_nil].each do |the_user|
      assert_not ApplicationPolicy.new(the_user, :application).admin_required?
    end
  end
end
