class BillingCircle < ActiveRecord::Base
  #belongs_to :subscription, :class_name => 'Subscription', :foreign_key => 'subscr_id'
  has_one :account, :class_name => 'Account', :foreign_key => 'i_bilcircle'

  set_table_name "billingcircle"
  self.primary_key = "i_bilcircle"

  self.establish_connection($dbcon)
end