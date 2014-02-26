class Country < ActiveRecord::Base
  set_table_name "country"
  self.establish_connection($dbcon)
  self.primary_key = "country"
  #has_one :account, :class_name => 'Account', :foreign_key => 'country'
end
