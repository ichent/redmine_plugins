class KanbanIssue < ActiveRecord::Base
  unloadable

  belongs_to :issue
  belongs_to :user

  named_scope :last_category_position, lambda { |category_id|
    {
      :select => 'max(position) as position',
      :conditions => ["category_id = ?", category_id]
    }
  }

  # Called when an issue is updated.
  def self.update_from_issue(issue, kanban_params = {})
    return true if issue.nil?
    return true if kanban_params.blank?

    if !kanban_params[:kanban_view].blank? && kanban_params[:kanban_view].to_i == 1
      kanban_issue = KanbanIssue.find_or_initialize_by_issue_id(issue.id)

      kanban_issue.project_id = issue.project_id

      # Kanban category
      if kanban_issue.category_id != kanban_params[:kanban_category]
        kanban_categories = KanbanCategory.find(:all, :order => :position)

        category = kanban_categories[0][:id]

        kanban_categories.each {|cat|
          if cat[:id] == kanban_params[:kanban_category].to_i
            category = cat[:id]
          end
        }
        
        kanban_issue.category_id = category
      end

      if kanban_issue.new_record?
        #Kanban position
        position = KanbanIssue.last_category_position(kanban_issue.category_id).find(:first)
        kanban_issue.position = position.position.to_i + 1

        kanban_issue.issue_id = issue.id
        kanban_issue.user_id = issue.author_id
      end

      return kanban_issue.save
    else
      KanbanIssue.destroy_all(['issue_id = ?', issue.id])
    end

    return true
  end

  def self.check_issue_exist(issue_id)
    kanban_issue = KanbanIssue.find_by_issue_id(issue_id)

    return kanban_issue
  rescue
    return false
  end
end
