require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "should get autocomplete" do
    get search_autocomplete_url
    assert_response :success
  end
end
