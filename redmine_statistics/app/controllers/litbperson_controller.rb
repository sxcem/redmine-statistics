require 'chart'
require 'settings'

class LitbpersonController < ApplicationController
  unloadable

  before_filter :require_login
  
  def index
    #首页路径
    @back_url = url_for(:controller => 'statistics', :action => 'index')
    #获取所有优先级
    @priorities = Settings::PRIORITIES

    @users = Settings::USERS

    #获得测试人员和开发人员列表
    @test_users = Settings.get_test_user
    @dev_users = Settings.get_dev_user

    #如果是POST请求
    if request.post?
      #获取POST参数
      @chart_id = params[:chart_id]
      user_id = params[:user_id]
      priority_id = params[:priority_id]

      role_id = params[:role_id]

      #判断请求人员是开发人员还是测试人员
      if role_id == '2'
        @is_tester = true
      else
        @is_tester = false
      end

      #如果是标准报表
      if @chart_id == '1'
        #如果没有输入日期
        if params[:date_from].blank? or params[:date_to].blank?
          if user_id == 'all'
            @personal_issues = PersonalIssue.find(:all)
          else
            @personal_issues = PersonalIssue.find(:all, :conditions => {:user_id => user_id})
          end
        #如果输入了查询日期
        else
          if user_id == 'all'
            @personal_issues = PersonalIssue.find(:all, :conditions => {:created_on => (params[:date_from]..params[:date_to])})
          else
            @personal_issues = PersonalIssue.find(:all, :conditions => {:user_id => user_id, :created_on => (params[:date_from]..params[:date_to])})
          end
        end
        #获取统计的综合结果
        @investigated_issues = 0
        @resolved_issues = 0
        inves_time = 0
        @reopened_issues = 0
        @regression_issues = 0
        @average_inves_time = 0

        @found_issues = 0
        @fixed_issues = 0
        @not_issues = 0
        @fix_reopen_issues = 0

        @personal_issues.each do |p|
          @investigated_issues += p.investigating_issues
          @resolved_issues += p.resolved_issues
          inves_time += p.inves_time
          @reopened_issues += p.reopened_issues
          @regression_issues += p.regression_issues
          @found_issues += p.found_issues
          @fixed_issues += p.fixed_issues
          @not_issues += p.not_issues
          @fix_reopen_issues += p.fix_reopen_issues
        end

        #平均调研时间 单位为小时
        @average_inves_time = StatisticsHelper.get_divided_number(inves_time, @investigated_issues)
      #如果是详细报表
      elsif @chart_id == '2'                                                    
        if params[:date_from].blank? or params[:date_to].blank?
          if user_id == "all" and priority_id == 'all'
            @personal_priority_issues = PersonalPriorityIssue.find(:all)
          elsif user_id != 'all' and priority_id == 'all'
            @personal_priority_issues = PersonalPriorityIssue.find(:all, :conditions => {:user_id => user_id})
          elsif user_id == 'all' and priority_id != 'all'
            @personal_priority_issues = PersonalPriorityIssue.find(:all, :conditions => {:priority_id => priority_id})
          else
            @personal_priority_issues = PersonalPriorityIssue.find(:all, :conditions => {:priority_id => priority_id, :user_id => user_id})
          end
        else
          if user_id == "all" and priority_id == 'all'
            @personal_priority_issues = PersonalPriorityIssue.find(:all, :conditions => {:created_on => (params[:date_from]..params[:date_to])})
          elsif user_id != 'all' and priority_id == 'all'
            @personal_priority_issues = PersonalPriorityIssue.find(:all, :conditions => {:user_id => user_id, :created_on => (params[:date_from]..params[:date_to])})
          elsif user_id == 'all' and priority_id != 'all'
            @personal_priority_issues = PersonalPriorityIssue.find(:all, :conditions => {:priority_id => priority_id, :created_on => (params[:date_from]..params[:date_to])})
          else
            @personal_priority_issues = PersonalPriorityIssue.find(:all, :conditions => {:priority_id => priority_id, :user_id => user_id, :created_on => (params[:date_from]..params[:date_to])})
          end
        end

        @investigated_issues = 0
        @resolved_issues = 0
        @reopened_issues = 0
        @regression_issues = 0

        @found_issues = 0
        @fixed_issues = 0
        @not_issues = 0
        @fix_reopen_issues = 0

        @personal_priority_issues.each do |p|
          @investigated_issues += p.investigating_issues
          @resolved_issues += p.resolved_issues
          @reopened_issues += p.reopened_issues
          @regression_issues += p.regression_issues

          @found_issues += p.found_issues
          @fixed_issues += p.fixed_issues
          @not_issues += p.not_issues
          @fix_reopen_issues += p.fix_reopen_issues
        end

      #如果是标准报表趋势图
      else @chart_id == '3'                                                     
        if params[:date_from] > params[:date_to]
          @line_chart = "end_date_can_not_before_start_date.jpg "
        else
          min_date = nil
          max_date = nil
          if params[:date_from].blank? or params[:date_to].blank?
            min_date = PersonalIssue.minimum(:created_on, :conditions => {:user_id => user_id})
            max_date = PersonalIssue.maximum(:created_on, :conditions => {:user_id => user_id})
          else
            min_date = PersonalIssue.minimum(:created_on, :conditions => {:user_id => user_id, :created_on => (params[:date_from]..params[:date_to])})
            max_date = PersonalIssue.maximum(:created_on, :conditions => {:user_id => user_id, :created_on => (params[:date_from]..params[:date_to])})
          end
          if min_date != nil and max_date != nil
            inteval = Chart.getinteval(min_date, max_date)

            issues_dev_hash = Hash.new
            issues_test_hash = Hash.new
            time_line = Array.new
            inves_trend = Array.new
            resolved_trend = Array.new
            reopened_trend = Array.new
            regression_trend = Array.new
            found_trend = Array.new
            not_issues_trend = Array.new
            fix_reopen_trend = Array.new
            fixed_trend = Array.new

            date = min_date
            while date <= max_date
              personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => user_id, :created_on => date})
              if personal_issue != nil
                inves_trend << personal_issue.investigating_issues
                resolved_trend << personal_issue.resolved_issues
                reopened_trend << personal_issue.reopened_issues
                regression_trend << personal_issue.regression_issues
                found_trend << personal_issue.found_issues
                not_issues_trend << personal_issue.not_issues
                fix_reopen_trend << personal_issue.fix_reopen_issues
                fixed_trend << personal_issue.fixed_issues
              else
                inves_trend << 0
                resolved_trend << 0
                reopened_trend << 0
                found_trend << 0
                not_issues_trend << 0
                fix_reopen_trend << 0
                fixed_trend << 0
              end
              time_line << date.strftime("%m-%d")
              date = date + inteval
            end

            max_temp1 = inves_trend.max > resolved_trend.max ? inves_trend.max : resolved_trend.max
            max_temp2 = reopened_trend.max > regression_trend.max ? reopened_trend.max : regression_trend.max
            max_dev_value = max_temp1 > max_temp2 ? max_temp1 : max_temp2

            max_temp1 = found_trend.max > not_issues_trend.max ? found_trend.max : not_issues_trend.max
            max_temp2 = fix_reopen_trend.max > fixed_trend.max ? fix_reopen_trend.max : fixed_trend.max
            max_test_value = max_temp1 > max_temp2 ? max_temp1 : max_temp2


            issues_dev_hash["Investigated Issues"] = inves_trend
            issues_dev_hash["Resolved Issues"] = resolved_trend
            issues_dev_hash["Reopened Issues"] = reopened_trend
            issues_dev_hash["Regression Issues"] = regression_trend
            issues_test_hash["Found Issues"] = found_trend
            issues_test_hash["NotABug Issues"] = not_issues_trend
            issues_test_hash["FixReopen Issues"] = fix_reopen_trend
            issues_test_hash["Fixed Issues"] = fixed_trend

            chart_title = "#{User.find(user_id).name} Issues Trend Line"

            chart = Chart.new(chart_title, 'line_chart')
            chart.set_chart_color('type color')
            chart.generate_x_labels(time_line)
            chart.size = "800x300"
            unless @is_tester
              chart.data_source = issues_dev_hash
              chart.get_y_labels(max_dev_value)
            else
              chart.data_source = issues_test_hash
              chart.get_y_labels(max_test_value)
            end

            @line_chart = chart.to_url
          else
            @line_chart = "no_data_to_display.jpg"
          end
        end
      end
    else
      #在首页上默认显示一百个记录
      @personal_issues = PersonalIssue.find(:all, :limit => 100)                
      
      @investigated_issues = 0
      @resolved_issues = 0
      inves_time = 0
      @reopened_issues = 0
      @regression_issues = 0
      @average_inves_time = 0

      #获得该列表的各项的总数
      @personal_issues.each do |p|                                              
        @investigated_issues += p.investigating_issues
        @resolved_issues += p.resolved_issues
        inves_time += p.inves_time
        @reopened_issues += p.reopened_issues
        @regression_issues += p.regression_issues
      end

      @average_inves_time = StatisticsHelper.get_divided_number(inves_time, @investigated_issues)
    end
  end

end
