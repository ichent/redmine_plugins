# StateController
#
# Controller for working with states. State is a part of address

class StateController < ApplicationController
  unloadable

  def index
    @country = params[:account_country]
    
    if @country == 'United States of America'
       @state = State.find(:all, :conditions => "state!='--'").map {|p| p.state}
    else
       @state = '--'
    end
    
    render :partial => "state", :layout => false
  end
end