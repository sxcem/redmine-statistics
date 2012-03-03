class TeamIssue < ActiveRecord::Base
  unloadable

  #将对象实例化函数设置为私有函数
  private_class_method :new

  #定义工厂方法
  def TeamIssue.new_normal
    return new
  end

  def TeamIssue.new_advance
    team_issue = new
    team_issue.investigating_issues = 0
    team_issue.resolved_issues = 0
    team_issue.reopened_issues = 0
    team_issue.regression_issues = 0
    team_issue.inves_time = 0
    team_issue.found_issues = 0
    team_issue.fixed_issues = 0
    team_issue.not_issues = 0
    team_issue.fix_reopen_issues = 0

    return team_issue
  end
end
