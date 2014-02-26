class CreateKanbanCategories < ActiveRecord::Migration
  def self.up
    create_table :kanban_categories do |t|
      t.column :name, :string, :limit => 30
      t.column :position, :integer, :null => true
    end

    KanbanCategory.create :name => "In work", :position => 1
    KanbanCategory.create :name => "Approved", :position => 2
    KanbanCategory.create :name => "Assigned", :position => 3
    KanbanCategory.create :name => "Completed", :position => 4
    KanbanCategory.create :name => "Queue", :position => 5
  end
  
  def self.down
    drop_table :kanban_categories
  end
end