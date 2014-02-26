class CreditCard < ActiveRecord::Base
  has_one :account, :class_name => 'Account', :foreign_key => 'i_cc'

  set_table_name "creditcard"
  set_inheritance_column "ruby_type"

  self.establish_connection($dbcon)
  self.primary_key = "i_cc"

  validates_presence_of :first_name, :last_name, :address, :zip, :state, :country, 
                        :phone, :city, :cc_number, :cvv, :cc_expired
  validates_format_of :cc_number, :with => /^([0-9]+)$/
end