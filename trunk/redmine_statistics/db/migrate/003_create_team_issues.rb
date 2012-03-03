class CreateTeamIssues < ActiveRecord::Migration
  def self.up
    create_table :team_issues do |t|

	  t.column :group_id, :integer
		
	  t.column :group_name, :string
	  
	  t.column :group_type, :string
	
      t.column :project_name, :string
	  
	  t.column :project_id, :integer
	  
	  t.column :version_id, :integer
	  
	  t.column :version_name, :string

      t.column :user_id, :integer

      t.column :dev_name, :string
	  
	  t.column :investigating_issues, :integer

      t.column :resolved_issues, :integer

      t.column :reopened_issues, :integer
	  
	  t.column :regression_issues, :integer
	  
	  t.column :found_issues, :integer
	  
	  t.column :not_issues, :integer
	  
	  t.column :fix_reopen_issues, :integer
	  
	  t.column :fixed_issues, :integer
	  
	  t.column :inves_time, :integer

      t.column :created_on, :date

    end
  end

  def self.down
    drop_table :team_issues
  end
end
