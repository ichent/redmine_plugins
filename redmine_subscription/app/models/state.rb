class State < ActiveRecord::Base
set_table_name "state"
self.establish_connection($dbcon)
self.primary_key="state"
#has_one :aaccount, :class_name=>'Account', :foreign_key=>'state'
end
