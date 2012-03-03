class PersonalPriorityIssue < ActiveRecord::Base
  unloadable

  #将new函数声明为私有函数
  private_class_method :new

  def PersonalPriorityIssue.new_normal
    new
  end

  def PersonalPriorityIssue.new_advance
    personal_priority_issue = new
    personal_priority_issue.investigating_issues = 0
    personal_priority_issue.resolved_issues = 0
    personal_priority_issue.regression_issues = 0
    personal_priority_issue.reopened_issues = 0
    personal_priority_issue.found_issues = 0
    personal_priority_issue.fixed_issues = 0
    personal_priority_issue.not_issues = 0
    personal_priority_issue.fix_reopen_issues = 0

    return personal_priority_issue
  end
end
