require "application_system_test_case"

class UserManagesOrdersTest < ApplicationSystemTestCase
  # TODO: Add test for creating a new order
  # TODO: Add test for updating an order

  test "deleting an order" do
    user = create(:user)
    sign_in(user)
    order = create(:order)
    visit order_url(order)

    click_on "Destroy this order"

    assert_text "Order was successfully destroyed"
  end
end
