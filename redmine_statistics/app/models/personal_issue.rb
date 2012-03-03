class PersonalIssue < ActiveRecord::Base
  unloadable

  #将函数new声明为私有函数
  private_class_method :new

  #定义简单的初始化函数
  def PersonalIssue.new_normal
    new
  end

  def PersonalIssue.new_advance
    personal_issue = new
    personal_issue.investigating_issues = 0
    personal_issue.resolved_issues = 0
    personal_issue.reopened_issues = 0
    personal_issue.regression_issues = 0
    personal_issue.inves_time = 0
    personal_issue.found_issues = 0
    personal_issue.fixed_issues = 0
    personal_issue.not_issues = 0
    personal_issue.fix_reopen_issues = 0

    return personal_issue
  end

  #定义复杂的初始化函数
end
