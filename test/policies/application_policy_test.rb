# frozen_string_literal: true

require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = create(:admin)
    @teacher = create(:teacher)
    @student = create(:student)
    @record = :some_record
    @the_nil = nil
  end

  test "admin_required?" do
    assert ApplicationPolicy.new(@admin, @record).admin_required?

    [@teacher, @student, @the_nil].each do |target_user|
      assert_not ApplicationPolicy.new(target_user, @record).admin_required?
    end
  end

  test "teacher_required?" do
    assert ApplicationPolicy.new(@teacher, @record).teacher_required?

    [@admin, @student, @the_nil].each do |target_user|
      assert_not ApplicationPolicy.new(target_user, @record).teacher_required?
    end
  end

  test "student_required?" do
    assert ApplicationPolicy.new(@student, @record).student_required?

    [@admin, @teacher, @the_nil].each do |target_user|
      assert_not ApplicationPolicy.new(target_user, @record).student_required?
    end
  end

  test "teacher_or_admin_required?" do
    [@admin, @teacher].each do |target_user|
      assert ApplicationPolicy.new(target_user, @record).teacher_or_admin_required?
    end

    [@student, @the_nil].each do |target_user|
      assert_not ApplicationPolicy.new(target_user, @record).teacher_or_admin_required?
    end
  end

  test "index? returns false for all users" do
    [@admin, @teacher, @student, @the_nil].each do |user|
      policy = ApplicationPolicy.new(user, @record)

      assert_not policy.index?
    end
  end

  test "show? returns false for all users" do
    [@admin, @teacher, @student, @the_nil].each do |user|
      policy = ApplicationPolicy.new(user, @record)

      assert_not policy.show?
    end
  end

  test "create? returns false for all users" do
    [@admin, @teacher, @student, @the_nil].each do |user|
      policy = ApplicationPolicy.new(user, @record)

      assert_not policy.create?
    end
  end

  test "update? returns false for all users" do
    [@admin, @teacher, @student, @the_nil].each do |user|
      policy = ApplicationPolicy.new(user, @record)

      assert_not policy.update?
    end
  end

  test "destroy? returns false for all users" do
    [@admin, @teacher, @student, @the_nil].each do |user|
      policy = ApplicationPolicy.new(user, @record)

      assert_not policy.destroy?
    end
  end

  test "new? delegates to create?" do
    policy = ApplicationPolicy.new(@admin, @record)

    assert_equal policy.create?, policy.new?
  end

  test "edit? delegates to update?" do
    policy = ApplicationPolicy.new(@admin, @record)

    assert_equal policy.update?, policy.edit?
  end

  test "initialize stores user and record" do
    policy = ApplicationPolicy.new(@admin, @record)

    assert_equal @admin, policy.user
    assert_equal @record, policy.record
  end

  test "initialize handles nil user" do
    policy = ApplicationPolicy.new(@the_nil, @record)

    assert_nil policy.user
    assert_equal @record, policy.record
  end

  test "Scope initialize stores user and scope" do
    scope = :some_scope
    scope_instance = ApplicationPolicy::Scope.new(@admin, scope)

    assert_equal @admin, scope_instance.send(:user)
    assert_equal scope, scope_instance.send(:scope)
  end

  test "Scope resolve raises NoMethodError" do
    scope_instance = ApplicationPolicy::Scope.new(@admin, :some_scope)
    error = assert_raises(NoMethodError) do
      scope_instance.resolve
    end
    assert_includes error.message, "You must define #resolve in ApplicationPolicy::Scope"
  end
end
