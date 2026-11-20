require Rails.root.join("db/migrate/20261029090000_create_push_notifications").to_s

# Homelab only. This database ran the web push alpha, whose migrations used
# version 20261029090000 (create_web_push_notifications) and 20261103000000.
# Main's create_push_notifications reuses that version, so it would never run.
# The alpha rows are one test browser registration and its deliveries.
class BridgeWebPushAlphaSchema < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:web_push_deliveries)

    drop_table :web_push_deliveries
    drop_table :web_push_subscriptions
    remove_column :insights, :notification_version
    CreatePushNotifications.new.migrate(:up)
    execute "DELETE FROM schema_migrations WHERE version = '20261103000000'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
