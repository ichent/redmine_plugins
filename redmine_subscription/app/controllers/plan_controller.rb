# PlanController
#
# Controller for working with plans

class PlanController < ApplicationController
  unloadable

  def index
    @account = Account.find($uid)

    # Get a plan, which was selected
    if !params[:plan].nil?
      plan = params[:plan].to_i

      @plan = PlanCC.find_by_i_plan(plan)
    else
      @plan = PlanCC.find_by_i_plan(0)
    end

    # Calculate a sum
    if !params[:src].nil? && params[:src] == 'true'
      @bill_circle = BillingCircle.find(:first, :conditions => "bilcircle = 12")
      @price = (@plan.price*@bill_circle.bilcircle).to_f*((100-@bill_circle.discount).to_f/100)
      @year = 1
    else
      @price = @plan.price
      @year = 0
    end

    render :partial => "plan", :layout => false
  end

private
  def rescue_action(exception)
    render_404
  end
end

