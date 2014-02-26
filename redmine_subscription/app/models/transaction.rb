class Transaction < ActiveRecord::Base
  belongs_to :subscription, :class_name => 'Subscription', :foreign_key => 'subscr_id'
  set_table_name "transaction_cc"

  self.establish_connection($dbcon)
end
