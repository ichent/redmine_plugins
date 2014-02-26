class BlockedIp < ActiveRecord::Base
  set_table_name "blockedip"

  self.establish_connection($dbcon)
  self.primary_key = "i_ip"

  #validates_presence_of :firstname, :lastname, :address, :zip, :state, :country
  #validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
end