class KanbanPermissionsController < ApplicationController
  unloadable

  before_filter :require_admin

  def index
    scope = User

    @limit = per_page_option
    
    c = ARCondition.new(["status <> 0 and admin = 0 and type = 'User'"])

    @user_count = scope.count(:conditions => c.conditions)
    @user_pages = Paginator.new self, @user_count, @limit, params['page']
    @offset ||= @user_pages.current.offset
    @users = scope.find :all,
                        :order => :login,
                        :conditions => c.conditions,
                        :select => "users.*, kanban_permissions.view, kanban_permissions.manage",
                        :joins => "LEFT JOIN `kanban_permissions` ON kanban_permissions.user_id = users.id",
                        :limit  =>  @limit,
                        :offset =>  @offset

    render :action => "index", :layout => false if request.xhr?
  end

  def update_permission
    if request.xhr?
      unless params[:user_id].blank? && params[:checked].blank? && params[:type].blank? && ['view', 'manage'].include?(params[:type])
        user_permission = KanbanPermission.find(:first, 
                                                :conditions => ['user_id = ?', params[:user_id].to_i])
        
        if user_permission.blank?
          user_permission = KanbanPermission.new
        end

        user_permission.user_id = params[:user_id]
        user_permission[params[:type]] = params[:checked].to_i == 1 ? 1 : 0

        user_permission.save
      end
    else
      redirect_to :controller => 'kanban_permissions'
    end

    render :nothing => true
  end
end