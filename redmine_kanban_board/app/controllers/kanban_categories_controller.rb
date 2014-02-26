class KanbanCategoriesController < ApplicationController
  unloadable
  
  before_filter :require_admin
         
  def index
    @kanban_category_pages, @kanban_categories = paginate :kanban_categories, :per_page => 25, :order => "position"
    render :action => "index", :layout => false if request.xhr?
  end
  
  def update
    @kanban_category = KanbanCategory.find(params[:id])
    
    if @kanban_category.update_attributes(params[:kanban_category])
      flash[:notice] = l(:notice_successful_update)
    end
	
    redirect_to :action => 'index'
  end  
end
