module RedmineKanbanBoard
  module Patches
    # Patches Redmine's Issues dynamically.  Adds a +after_save+ filter.
    module IssuePatch
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)

        # Same as typing in the class
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development

          #after_save :update_kanban_from_issue
          after_destroy :remove_kanban_issues
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        # This will update the KanbanIssues associated to the issue
        #def update_kanban_from_issue
        #  self.reload
        #  KanbanIssue.update_from_issue(self, {:kanban_view => params[:kanban_view],
        #                                       :kanban_category => params[:kanban_category]})
        #  return true
        #end

        def remove_kanban_issues
          KanbanIssue.destroy_all(['issue_id = (?)', self.id]) if self.id
        end
      end
    end
  end
end
