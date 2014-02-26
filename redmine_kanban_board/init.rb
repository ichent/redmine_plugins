require 'redmine'

# Patches to the Redmine core.
require 'dispatcher'

Dispatcher.to_prepare :redmine_kanban do
  require_dependency 'issue'

  unless Issue.included_modules.include? RedmineKanbanBoard::Patches::IssuePatch
    Issue.send(:include, RedmineKanbanBoard::Patches::IssuePatch)
  end
end

require_dependency 'redmine_kanban_board/hooks/view_issues_form_details_bottom_hook'
require_dependency 'redmine_kanban_board/hooks/controller_issues_edit_after_save_hook'

Redmine::Plugin.register :redmine_kanban_board do
  name 'Redmine Kanban Board plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  menu(:top_menu,
       :kanban,
       {:controller => 'kanban', :action => 'index'},
       :caption => :text_kanban_title,
       :if => Proc.new { KanbanPermission.allowed_to?(:view, User.current) })
end