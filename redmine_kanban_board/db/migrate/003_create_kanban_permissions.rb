class CreateKanbanPermissions < ActiveRecord::Migration
  def self.up
    create_table :kanban_permissions do |t|
      t.column :user_id, :integer
      t.column :view, :integer, :default => 0, :limit => 1
      t.column :manage, :integer, :default => 0, :limit => 1
    end

    add_index :kanban_permissions, :user_id
  end
  
  def self.down
    drop_table :kanban_permissions
  end
end
