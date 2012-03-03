class CreateActiveIssues < ActiveRecord::Migration
  def self.up
    create_table :active_issues do |t|

      t.column :project_id, :integer, :null => false

      t.column :project_name, :string, :null => false
	  
	  t.column :version_id, :integer
	  
	  t.column :version_name, :string

      t.column :issues_number, :integer, :null => false, :default => 0

      t.column :priority_id, :integer, :null => false

      t.column :priority_name, :string, :null => false

      t.column :tracker_id, :integer, :null => false

      t.column :tracker_name, :string, :null => false

      t.column :created_on, :date, :null => false

    end
  end

  def self.down
    drop_table :active_issues
  end
end
