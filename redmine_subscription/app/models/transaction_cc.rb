class TransactionCC < ActiveRecord::Base
  #belongs_to :subscription, :class_name => 'Subscription', :foreign_key => 'subscr_id'
  set_table_name "transaction_cc"
  set_inheritance_column "ruby_type"

  self.establish_connection($dbcon)
end
