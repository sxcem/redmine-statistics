require 'chart'
require 'settings'

class OngoingController < ApplicationController
  unloadable

  before_filter :require_login

  #根据不同的查询条件生成不同的SQL
  def get_issues(project_id, status_id, filter_status, assigned_to_id, filter_assigned_to, tracker_id, filter_tracker, version_id, filter_version, six_update, filter_update)
    conditions = Hash.new
    conditions["issues.project_id"] = project_id
    conditions["issue_statuses.is_closed"] = '0'
    if status_id != 'all' and filter_status
      conditions["issues.status_id"] = status_id
    end
    if assigned_to_id != 'all' and filter_assigned_to
      conditions["issues.assigned_to_id"] = assigned_to_id
    end
    if tracker_id != 'all' and filter_tracker
      conditions["issues.tracker_id"] = tracker_id
    end
    if version_id != 'all' and filter_version
      conditions["issues.fixed_version_id"] = version_id
    end

    if filter_update
      conditions["issues.updated_on"] = ("1980-02-01 09:30:45"..six_update.to_s)
    end
    
    issues = Issue.find(:all, :include => [:status], :conditions => conditions)

    return issues
  end

  def index
    #要显示的项目
    @projects = Settings::PROJECTS
    #显示版本号
    @versions = Settings.get_versions
    #要显示的状态
    @statuses = Settings::STATUSES
    #要显示的tracker
    @trackers = Settings::TRACKERS
    #首页路经
    @back_url = url_for(:controller => 'statistics', :action => 'index')

    #获取当前时间，并换算到秒
    @now_time = Time.now.to_i

    #获得人员列表
    @users = Settings::USERS

    if request.post?
      #获取POST参数
      @chart_id = params[:chart_id]

      @project_id = params[:project_id]
      @status_id = params[:status_id]
      @assigned_to_id = params[:assigned_to_id]
      @tracker_id = params[:tracker_id]
      @version_id = (params[:version_id] == " ") ? nil : params[:version_id]

      #如果是标准报表
  
      if @chart_id == '1'
        @issues = get_issues(@project_id, @status_id, true, @assigned_to_id, true, @tracker_id, true, @version_id, true, 0, false)
      #如果是低活动率表
      elsif @chart_id == '2'
        #获取6天前的时间
        @six_day_ago = Time.now - 60*60*24*6
        #格式化时间为'2010-10-9 09:30:45'的形式
        @six_day_ago = @six_day_ago.strftime("%Y-%m-%d %H:%M:%S")

        @issues = get_issues(@project_id, 0, false, @assigned_to_id, true, 0, false, @version_id, true, @six_day_ago, true)

      #如果是优先级饼图
      elsif @chart_id == '3'
       issues = get_issues(@project_id, 0, false, 0, false, @tracker_id, true, @version_id, true, 0 ,false)
       #存储优先级issues数目,Hash结构key-value
       priority_number = Hash.new
       for issue in issues do
         priority_name = Enumeration.find(issue.priority_id).name
         if priority_number.has_key?(priority_name)
           priority_number[priority_name] += 1
         else
           priority_number[priority_name] = 1
         end
       end

       title = "项目名:#{Project.find(@project_id).name} 目标版本: #{@version_name} 跟踪类型:#{Tracker.find(@tracker_id).name}"
       #生成图形的url
       pie_chart = Chart.new(title, 'pie_chart', priority_number, 500, 400)
       pie_chart.set_chart_color('priority color')

       @chart_url =pie_chart.to_url

      #如果是在其他项目下的调研问题列表
      elsif @chart_id == '4'
       #存储其他项目下的调研问题列表，哈希表结构可以key-array
       @other_project_inves = Hash.new

       #得到所有处于调研中的项目
       all_inves_issues = Issue.find(:all,
                                       :include => [:status],
                                       :conditions => ["issue_statuses.name = '#{Settings::INVESTIGATING_NAME}'"])

       all_inves_issues.each do |a|
         #找出当前issue的所有更新记录
         journal =Journal.find(:all, :conditions => {:journalized_id => a.id})
         #对于每条记录，查询更新详情
         journal.each do |j|
           #找出最早的将project更新的记录
           journal_detail = JournalDetail.find(:first, :conditions => {:prop_key => 'project_id',:journal_id => j.id})
            #如果存在这样的记录
            unless journal_detail == nil
              @other_project_inves[a.id] = Array.new
              @other_project_inves[a.id] << Project.find(journal_detail.old_value).name
              @other_project_inves[a.id] << Project.find(a.project_id).name
              @other_project_inves[a.id] << Enumeration.find(a.priority_id).name
              #如果未指派给任何人，则指派人为空
              if a.assigned_to_id.blank?
                @other_project_inves[a.id] << " "
              else
                @other_project_inves[a.id] << User.find(a.assigned_to_id).name
              end
              @other_project_inves[a.id] << Tracker.find(a.tracker_id).name
              @other_project_inves[a.id] << a.start_date
              @other_project_inves[a.id] << a.updated_on
              @other_project_inves[a.id] << format("%.1f",(@now_time - a.updated_on.to_i)/(60*60.0*24))
           end
         end
       end
        
      end
    #什么都不是，默认列表
    else
      @issues =  Issue.find(:all,
                          :include => [:status],
                          :conditions => "issue_statuses.is_closed = '0'")
    end
  end
end
