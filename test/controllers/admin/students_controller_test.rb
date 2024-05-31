require 'test_helper'

class Admin::StudentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:one)
  end

  test 'should update student' do
    @student.update_attribute(:email, 'nottest@nottest.com')

    patch admin_student_url(@student), params: { student: { email: 'test@test.com' } }
    @student.reload
    assert_equal 'test@test.com', @student.email
    assert_redirected_to admin_student_url(@student)
  end
end
