class CreatePersonalPriorityIssues < ActiveRecord::Migration
  def self.up
    create_table :personal_priority_issues do |t|

      t.column :user_id, :integer

      t.column :dev_name, :string

      t.column :priority_id, :integer

      t.column :priority_name, :string

      t.column :investigating_issues, :integer

      t.column :resolved_issues, :integer

      t.column :regression_issues, :integer

      t.column :reopened_issues, :integer
	  
	  t.column :found_issues, :integer
	  
	  t.column :fixed_issues, :integer
	  
	  t.column :not_issues, :integer
	  
	  t.column :fix_reopen_issues, :integer

      t.column :created_on, :date

    end
  end

  def self.down
    drop_table :personal_priority_issues
  end
end
