require 'test_helper'

class Admins::HomesControllerTest < ActionDispatch::IntegrationTest
  test 'should get top' do
    get admins_homes_top_url
    assert_response :success
  end

  test 'should get analysis' do
    get admins_homes_analysis_url
    assert_response :success
  end
end
