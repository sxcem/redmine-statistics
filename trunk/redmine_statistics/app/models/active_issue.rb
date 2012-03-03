class ActiveIssue < ActiveRecord::Base
  unloadable
  
  private_class_method :new
  
  def ActiveIssue.new_normal
    new
  end
  
  def ActiveIssue.new_advance
	active_issue = new
	return active_issue
  end
  
end
