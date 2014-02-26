module AppControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.send(:append_before_filter, :limits)
  end

  module InstanceMethods
    # Custom includes for tweaking the design and behavior on the fly
    def limits
      if Account.find($uid).nil? || Account.find($uid).plan.nil?
        flash[:error] = 'Your account has some technical issues. Please contact technical support to resolve them.'
        redirect_to :controller => 'account', :action => 'login' unless controller_name == 'account'
      else
        if User.current.admin?
          #ccount = (Subscription.count :conditions => "active=1 and i_account=#{$uid}").to_i
          cancel_account = (Account.count :conditions => "i_account=#{$uid} and (active = 0 or NOW() > endtime)").to_i

          case cancel_account
            when 1
              flash[:error] = 'Your current subscription has been canceled. To avoid account locking, please reactivate your existing plan or subscribe to new plan.'
          end
        end

        if !Account.find($uid).active?
          if !User.current.admin?
            flash[:error] = 'Your subscription has expired. Please login as admin user.'
            
            if action_name != 'login'
              redirect_to :controller=>'account', :action=>'login' unless controller_name=='account' && action_name=='lost_password'
            end
          else
            redirect_to :controller => 'subs', :action=> 'index' if (action_name != 'logout' && controller_name != 'subs' && controller_name != 'plan' && controller_name != 'state')
          end
        end

        unless Account.find($uid).plan.maxprojects.to_i == 0
          if (controller_name=='projects' && (action_name=='add' || action_name=='copy') && Project.count()>=Account.find($uid).plan.maxprojects)
            flash[:error] = 'You have reached your maximum number of projects. To add additional project please upgrade your account.'
            redirect_to :controller => 'admin', :action => 'projects'
          end
        end

        unless Account.find($uid).plan.maxusers.to_i == 0
          if ((controller_name=='users' && (action_name=='add' || (action_name=='edit' && params[:user]!=nil && params[:user][:status]=="1"))) && User.count(:conditions=>"status=1") >=Account.find($uid).plan.maxusers)
            flash[:error] = 'You have reached your maximum number of users. To add additional user please upgrade your account.'
            redirect_to :controller => 'users', :action => 'index'
          end
        end

        if (controller_name=='projects' && action_name=='add_file')
          cl = request.env['CONTENT_LENGTH'].to_i || 0
          db_size = User.connection.select_one("SELECT sum(data_length)+sum(index_length) as asum FROM information_schema.tables where table_schema='#{User.configurations[ENV["RAILS_ENV"]]["database"]}' group by table_schema")["asum"].to_i
          attachments_size = Attachment.sum(:filesize)
          cur_space = (cl+db_size+attachments_size)/1073741824.0

          if (cur_space >= Account.find($uid).plan.maxspace)
            flash[:error] = 'You have reached your space quota. To get more disk space please upgrade your plan.'
            redirect_to :controller => 'admin', :action => 'projects'
          end
        end
      end

      false
    end
  end
end