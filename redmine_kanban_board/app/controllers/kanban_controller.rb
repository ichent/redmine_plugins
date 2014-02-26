class KanbanController < ApplicationController
  unloadable

  before_filter :require_permission_view, :only => [:index, :board]
  before_filter :require_permission_manage, :only => [:update_board, :show_hide_ticket, :change_board_view]

  def index
  end

  # View the board
  def board
    # List of categories for the board
    @kanban_categories = KanbanCategory.find(:all, :order => :position)

    # Search params (author)
    if params[:author].blank? || params[:author].to_i == 0
      c = ARCondition.new(["issues.author_id <> ?", 0])
      @search_author = nil
    else
      c = ARCondition.new(["issues.author_id = ?", params[:author].to_i])
      @search_author = params[:author].to_i
    end

    # Search params (assigned to)
    unless params[:assigned_to].blank? && params[:assigned_to].to_i == 0
      c << ["issues.assigned_to_id = ?", params[:assigned_to].to_i]
      @search_assigned_to = params[:assigned_to].to_i
    end

    # Search params (project)
    unless params[:project].blank? && params[:project].to_i == 0
      c << ["issues.project_id = ?", params[:project].to_i]
      @search_project = params[:project].to_i
    end

    # Show only is visible
    c << ["kanban_issues.is_hidden = 0"]

    # List of issues for the board
    @kanban_issues = KanbanIssue.find :all,
                                      :order => 'kanban_issues.category_id ASC, kanban_issues.position ASC',
                                      :include => [:issue, :user],
                                      :conditions => c.conditions
    # List of users
    @users = User.find(:all, :order => :login, :conditions => ["status = ?", 1])

    # List of projects
    @projects = Project.find(:all, :order => :name)
  end

  # Manage the boards
  def update_board
    if request.xhr?
      @kanban_categories = KanbanCategory.find(:all, :order => 'position ASC')

      @kanban_categories.each {|category|
        unless params["column" + category[:id].to_s].blank?
          category_issues = params["column" + category[:id].to_s].split(/,/)

          position = 1
          category_issues.each {|issue|
            issue.gsub! "item", ""

            if issue.to_i > 0
              # Update issue
              @kanban_issue = KanbanIssue.find_by_issue_id(issue.to_i)

              unless @kanban_issue.blank?
                @kanban_issue.category_id = category[:id]
                @kanban_issue.position = position
                @kanban_issue.save

                position += 1
              end
            end
          }
        end
      }
    else
      render_403
      return false
    end

    # Show only is visible
    c = ARCondition.new(["kanban_issues.is_hidden = 0"])

    # List of issues for the popups
    @kanban_issues = KanbanIssue.find :all,
                                      :order => 'kanban_issues.category_id ASC, kanban_issues.position ASC',
                                      :include => [:issue, :user],
                                      :conditions => c.conditions

    render :template => 'kanban/_update_board.rhtml', :layout => false
  end

  # Change the view of board
  def change_board_view
    if request.xhr?
      unless params["board_view"].blank?
        if params["board_view"] == 'full'
          c = ARCondition.new(["kanban_issues.is_hidden in (0,1)"])
        else
          c = ARCondition.new(["kanban_issues.is_hidden = 0"])
        end

        # Only with category_id = 1
        c << ["kanban_issues.category_id = 1"];

        # List of issues for the board
        @kanban_issues = KanbanIssue.find :all,
                                          :order => 'kanban_issues.position ASC',
                                          :include => [:issue, :user],
                                          :conditions => c.conditions
      end
    else
      render_403
      return false
    end

    render :template => 'kanban/_update_view_board.rhtml', :layout => false
  end

=begin
  # Show or hide the ticket
  def show_hide_ticket
    if request.xhr?

    else
      render_403
      return false
    end

    render :text => ActiveSupport::JSON.encode({'from' => render_pane_to_js(@from, @from_user),
                                                'to' => render_pane_to_js(@to, @to_user),
                                                'additional_pane' => render_pane_to_js(params[:additional_pane])})
  end
=end

  private

  def require_permission_view
    unless KanbanPermission.allowed_to?(:manage, User.current) || KanbanPermission.allowed_to?(:view, User.current) || User.current.admin?
      render_403
      return false
    end

    return true
  end

  def require_permission_manage
    unless KanbanPermission.allowed_to?(:manage, User.current) || User.current.admin?
      render_403
      return false
    end

    return true
  end
end