class Account < ActiveRecord::Base
  belongs_to :plan, :class_name => 'PlanCC', :foreign_key => 'i_plan'
  #belongs_to :country, :class_name => 'Country', :foreign_key => 'country'
  #belongs_to :state, :class_name => 'State', :foreign_key => 'state'
  belongs_to :billingcircle, :class_name => 'BillingCircle', :foreign_key => 'i_bilcircle'
  belongs_to :creditcard, :class_name => 'CreditCard', :foreign_key => 'i_cc'

  set_table_name "account"

  self.establish_connection($dbcon)
  self.primary_key = "i_account"

  validates_presence_of :firstname, :lastname, :address, :zip, :state, :country, :organization, :phone
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
end