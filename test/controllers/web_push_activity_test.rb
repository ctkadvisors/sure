require "test_helper"
require Rails.root.join("test/support/web_push_test_helper")

class WebPushActivityTest < ActionDispatch::IntegrationTest
  include WebPushTestHelper

  setup do
    @user = users(:family_admin)
    enable_web_push_preview(@user)
    sign_in @user
    @session = Current.session
  end

  test "an authenticated request refreshes only this user's current session registrations" do
    current_device = register_web_push(user: @user, session: @session)
    other_session_device = register_web_push(user: @user, endpoint: "https://fcm.googleapis.com/other-session")
    other_user_device = register_web_push(user: users(:family_member), endpoint: "https://fcm.googleapis.com/other-user")
    [ current_device, other_session_device, other_user_device ].each { |device| device.update_columns(last_seen_at: 2.hours.ago) }
    other_session_seen_at = other_session_device.reload.last_seen_at
    other_user_seen_at = other_user_device.reload.last_seen_at

    get settings_preferences_url

    assert_response :success
    assert_operator current_device.reload.last_seen_at, :>, 1.minute.ago
    assert_equal other_session_seen_at, other_session_device.reload.last_seen_at
    assert_equal other_user_seen_at, other_user_device.reload.last_seen_at
  end

  test "browser freshness does not change the deployed application's session authentication" do
    device = register_web_push(user: @user, session: @session)
    device.update_columns(last_seen_at: 31.days.ago)
    @session.update_columns(updated_at: 31.days.ago)
    assert_not device.reload.eligible?

    get settings_preferences_url

    assert_response :success
    assert Session.exists?(@session.id)
    assert device.reload.eligible?
  end
end
