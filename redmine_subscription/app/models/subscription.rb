class Subscription < ActiveRecord::Base
set_table_name "subscription"
self.establish_connection($dbcon)
self.primary_key="subscr_id"
has_many :transactions, :class_name=>'Transaction', :foreign_key=>'subscr_id'
end