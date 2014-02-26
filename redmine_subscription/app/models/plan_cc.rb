class PlanCC < ActiveRecord::Base
  has_one :account, :class_name => 'Account', :foreign_key => 'i_plan'

  set_table_name "plan_cc"

  self.establish_connection($dbcon)
  self.primary_key = "i_plan"

  def maxusers
    #if read_attribute(:maxusers) == 0
    #  "Unlimited"
    #else
      read_attribute(:maxusers)
    #end
  end

  def maxprojects
    #if read_attribute(:maxprojects) == 0
    #  "Unlimited"
    #else
      read_attribute(:maxprojects)
    #end
  end

  #def billcycle
  #  if read_attribute(:billcycle).capitalize == 'M'
  #    "month"
  #  else
  #    "year"
  #  end
  #end

  #def has_pair
    #Plan.find_by_i_plan(read_attribute(:i_plan), :conditions=>"modify=1 and active=1 and upper(billcycle)!='#{read_attribute(:billcycle).capitalize}'")
  #end
end