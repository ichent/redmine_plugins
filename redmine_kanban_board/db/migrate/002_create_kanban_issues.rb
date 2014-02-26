class CreateKanbanIssues < ActiveRecord::Migration
  def self.up
    create_table :kanban_issues do |t|
      t.column :user_id, :integer
      t.column :position, :integer
      t.column :issue_id, :integer
      t.column :project_id, :integer
      t.column :category_id, :integer
      t.column :is_hidden, :integer, :limit => 1, :default => 0
    end

    add_index :kanban_issues, :user_id
    add_index :kanban_issues, :issue_id
    add_index :kanban_issues, :category_id
    add_index :kanban_issues, :project_id
  end
  
  def self.down
    drop_table :kanban_issues
  end
end
