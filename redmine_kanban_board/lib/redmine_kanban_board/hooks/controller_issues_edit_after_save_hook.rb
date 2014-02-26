module RedmineContracts
  module Hooks
    class ControllerIssuesEditAfterSaveHook < Redmine::Hook::ViewListener
      def controller_issues_edit_after_save(context={})

        if context[:params].blank?
          return false
        end

        KanbanIssue.update_from_issue(context[:issue], {:kanban_category => context[:params][:kanban_category],
                                                        :kanban_view => context[:params][:kanban_view]})

        return true
      end

      alias_method :controller_issues_new_after_save, :controller_issues_edit_after_save
    end
  end
end
