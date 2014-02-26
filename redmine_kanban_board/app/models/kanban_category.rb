class KanbanCategory < ActiveRecord::Base
  acts_as_list
  
  before_destroy :delete_issues

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30
  validates_format_of :name, :with => /^[\w\s\'\-]*$/i  

  private

  # Deletes associated workflows
  def delete_issues
    KanbanIssue.delete_all(["category_id= :id", {:id => id}])
  end
end
