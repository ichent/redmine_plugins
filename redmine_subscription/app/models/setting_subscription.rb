class SettingSubscription < ActiveRecord::Base
  set_table_name "settings"

  self.establish_connection($dbcon)
end