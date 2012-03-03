require 'chart'
require 'settings'

class TrendController < ApplicationController
  unloadable

  before_filter :require_login

  #根据用户的过滤条件生成查询结果
  def get_active_issues(project_id, version_id, priority_id, tracker_id, date_from = nil, date_to = nil)
    conditions = Hash.new
    conditions[:project_id] = project_id
    if version_id != 'all'
      conditions[:version_id] = version_id
    end
    if priority_id != 'all'
      conditions[:priority_id] = priority_id
    end
    if tracker_id != 'all'
      conditions[:tracker_id] = tracker_id
    end
    if date_from != nil and date_to != nil
      conditions[:created_on] = (date_from.to_s..date_to.to_s)
    end
    
    active_issues = ActiveIssue.find(:all, :conditions => conditions)
    return active_issues
  end
  
  def index
    #首页路径
    @back_url = url_for(:controller => 'statistics', :action => 'index')
    #获取所有项目
    @projects = Settings::PROJECTS
    #获取所有目标版本
    @versions = Settings.get_versions
    #获取所有优先级
    @priorities = Settings::PRIORITIES
    #获取所有tracker
    @trackers = Settings::TRACKERS

    #如果有POST请求
    if request.post?
      #获取POST参数
      project_id = params[:project_id]
      priority_id = params[:priority_id]
      tracker_id = params[:tracker_id]
      version_id = (params[:version_id] == " ") ? nil : params[:version_id]

      #标准报表
      if params[:chart_id] == '1'
        if params[:date_from].blank? or params[:date_to].blank?
          @active_issues = get_active_issues(project_id, version_id, priority_id, tracker_id)
        else
          #获取查询的起始日期和结束日期
          date_from = Date.parse(params[:date_from])
          date_to = Date.parse(params[:date_to])
          @active_issues = get_active_issues(project_id, version_id, priority_id, tracker_id, date_from, date_to)
        end
      else
        #线性趋势图
        #如果项目为所有，则默认以第一个项目为准
        if project_id == 'all' or tracker_id == 'all'
          project_id = Project.find(:first).id
          tracker_id = Tracker.find(:first).id
        end
        #如果开始时间比结束时间晚
        if (params[:date_from] <=> params[:date_to]) == 1
          @line_chart = "end_date_can_not_before_start_date.jpg "
        #如果开始时间比结束时间早
        else
          min_date, max_date = nil, nil
          if params[:date_from].blank? or params[:date_to].blank?
            if version_id == nil
              logger.error("version id is nil")
            end
            if version_id == "all"
              min_date = ActiveIssue.minimum(:created_on, :conditions => {:project_id => project_id, :tracker_id => tracker_id})
              max_date = ActiveIssue.maximum(:created_on, :conditions => {:project_id => project_id, :tracker_id => tracker_id})
            else
              min_date = ActiveIssue.minimum(:created_on, :conditions => {:project_id => project_id, :tracker_id => tracker_id, :version_id => version_id})
              max_date = ActiveIssue.maximum(:created_on, :conditions => {:project_id => project_id, :tracker_id => tracker_id, :version_id => version_id})
            end
          else
            date_from = Date.parse(params[:date_from])
            date_to = Date.parse(params[:date_to])

            #得到在指定时间内所有issues的最早创建时间和最晚创建时间
            if version_id != "all"
              min_date = ActiveIssue.minimum(:created_on, :conditions => {:project_id => project_id, :version_id => version_id, :tracker_id => tracker_id, :created_on => (date_from.to_s..date_to.to_s)})
              max_date = ActiveIssue.maximum(:created_on, :conditions => {:project_id => project_id, :version_id => version_id, :tracker_id => tracker_id, :created_on => (date_from.to_s..date_to.to_s)})
            else
              min_date = ActiveIssue.minimum(:created_on, :conditions => {:project_id => project_id, :tracker_id => tracker_id, :created_on => (date_from.to_s..date_to.to_s)})
              max_date = ActiveIssue.maximum(:created_on, :conditions => {:project_id => project_id, :tracker_id => tracker_id, :created_on => (date_from.to_s..date_to.to_s)})
            end
          end
          #如果查询结果不为空
          if min_date != nil and max_date != nil
            #根据时间间隔，得到显示的时间粒度
            inteval = Chart.getinteval(min_date, max_date)

            #用来存储要显示的数据源
            priority_hash = Hash.new

            #存储x轴的数据
            timeline = Array.new

            #x轴要显示的长度
            x_length = (max_date - min_date)/inteval

            #存储数据源中的最大值
            max_value = 0

            #对于每一个优先级
            @priorities.each do |priority|
              #找出当前优先级的所有active_issues
              if version_id != 'all'
                active_issues = ActiveIssue.find(:all, :conditions => {:priority_id => priority.id, :project_id => project_id, :version_id => version_id, :tracker_id => tracker_id})
              else
                active_issues = ActiveIssue.find(:all, :conditions => {:priority_id => priority.id, :project_id => project_id, :tracker_id => tracker_id})
              end
              if !active_issues.empty?
                issue_date_trend = Array.new
                date = min_date
                while date <= max_date do
                  #查找指定日期的指定过滤条件的记录
                  if version_id != 'all'
                    active_issue = ActiveIssue.find(:first, :conditions => {:priority_id => priority.id, :created_on => date, :project_id => project_id, :version_id => version_id, :tracker_id => tracker_id})
                  else
                    active_issue = ActiveIssue.find(:first, :conditions => {:priority_id => priority.id, :created_on => date, :project_id => project_id, :tracker_id => tracker_id})
                  end
                  if active_issue == nil
                    issue_date_trend << 0
                  else
                    issue_date_trend << active_issue.issues_number
                    if active_issue.issues_number > max_value
                      max_value = active_issue.issues_number
                    end
                  end
                  timeline << date.strftime("%m-%d")
                  date += inteval
                end
                priority_hash[priority.name] = issue_date_trend
              end
            end
            #设置图表的title
            chart_title = "项目名称:#{Project.find(project_id)}  追踪类型:#{Tracker.find(tracker_id)} Trend Line"

            #生成图表
            line_chart = Chart.new(chart_title, 'line_chart', priority_hash, 800, 300)
            line_chart.set_chart_color('priority color')
            line_chart.generate_x_labels(timeline[0..x_length])
            line_chart.get_y_labels(max_value)

            #得到图表的url
            @line_chart = line_chart.to_url
          #如果查询结果为空，则显示如下图片
          else
            @line_chart = "no_data_to_display.jpg"
          end
        end
      end
    #如果没有POST请求，则默认显示如下列表，长度限制为最多35条(没什么意义)
    else
      @active_issues = ActiveIssue.find(:all, :limit => 35, :order => "id DESC")
    end
  end
end

