module RedmineKanbanBoard
  class ViewIssuesFormDetailsBottomHook < Redmine::Hook::ViewListener
    def view_issues_form_details_bottom(context = {})
      # the controller parameter is part of the current params object
      # This will render the partial into a string and return it.
      context[:controller].send(:render_to_string, {
         :partial => 'hooks/view_issues_form_details_bottom',
         :locals => context
       })
    end
  end
end