require 'chart'
require 'settings'

class LitbteamController < ApplicationController
  unloadable

  #before_filter :require_admin
  before_filter :require_login
  
  def index
    @back_url = url_for(:controller => 'statistics', :action => 'index')
    #获取所有的项目
    @projects = Settings::PROJECTS

    #获取团队名称
    @teams = Settings::TEAMS

    #获取目标版本
    @versions = Settings.get_versions

    #临时项目，使用在没有提供项目的情况下
    temp_project = Project.find(:first)

    #存储所有用户的issues信息
    @person_hash = Hash.new

    #用于存储开发人员的issues信息
    @team_dev_hash = Hash.new

    #用于存储测试人员的issues信息
    @team_test_hash = Hash.new

    #用于存储开发项目组的issues信息
    @team_dev_data_hash = Hash.new

    #用于存储测试项目组的issues信息
    @team_test_data_hash = Hash.new

    #存储符合查询条件的team issues
    team_issues = nil

    #当查询过滤条件下获取的结果集是空时，显示如下图片
    @bar_chart = "no_data_to_display.jpg"

    #统计每个团队的信息
    @group_total = [0,0,0,0,0,0,0,0,0]

    if request.post?
      #得到过滤信息
      @version_id = (params[:version_id] == " ") ? nil : params[:version_id]
      @project_id = params[:project_id]
      @chart_id = params[:chart_id]
      #如果是以团队观点查看
      if @chart_id == '5' or @chart_id == '6'
        @group_id = params[:group_id]
        if params[:date_from].blank? or params[:date_to].blank?
          if @project_id == 'all'
            team_issues = TeamIssue.find(:all, :conditions => {:group_id => @group_id})
          else
            if @version_id == 'all'
              team_issues = TeamIssue.find(:all, :conditions => {:group_id => @group_id, :project_id => @project_id})
            else
              team_issues = TeamIssue.find(:all, :conditions => {:group_id => @group_id, :project_id => @project_id, :version_id => @version_id})
            end
          end
        else
          if @project_id == 'all'
            team_issues = TeamIssue.find(:all, :conditions => {:group_id => @group_id, :created_on => (params[:date_from]..params[:date_to ])})
          else
            if @version_id == 'all'
              team_issues = TeamIssue.find(:all, :conditions => {:group_id => @group_id, :project_id => @project_id, :created_on => (params[:date_from]..params[:date_to ])})
            else
              team_issues = TeamIssue.find(:all, :conditions => {:group_id => @group_id, :project_id => @project_id, :version_id => @version_id, :created_on => (params[:date_from]..params[:date_to ])})
            end
          end
        end
      #如果是以项目观点进行查看
      else
        if params[:date_from].blank? or params[:date_to]
          if @version_id == 'all'
            team_issues = TeamIssue.find(:all, :conditions => {:project_id => @project_id})
          else
            team_issues = TeamIssue.find(:all, :conditions => {:project_id => @project_id, :version_id => @version_id})
          end
        else
          if @version_id == 'all'
            team_issues = TeamIssue.find(:all, :conditions => {:project_id => @project_id, :created_on => (params[:date_from]..params[:date_to ])})
          else
            team_issues = TeamIssue.find(:all, :conditions => {:project_id => @project_id, :version_id => @version_id, :created_on => (params[:date_from]..params[:date_to ])})
          end
        end
      end
    #如果没有得到POST请求，那么查找临时项目的所有目标版本
    else
      team_issues = TeamIssue.find(:all, :conditions => {:project_id => temp_project.id})
    end

    #如果结果集是空，那么所有的hash表都为空，图表均显示没有数据
    #如果结果集不为空
    unless team_issues.empty?
      #获取所有人的issues信息，@person_hash的结构是key—array，array中依次存储该person在指定时间内的issues情况综合
      team_issues.each do |t|
        if @person_hash.include?(t.user_id)
          @person_hash[t.user_id][0] += t.investigating_issues
          @person_hash[t.user_id][1] += t.resolved_issues
          @person_hash[t.user_id][2] += t.inves_time
          @person_hash[t.user_id][3] += t.reopened_issues
          @person_hash[t.user_id][4] += t.regression_issues
          @person_hash[t.user_id][5] += t.found_issues
          @person_hash[t.user_id][6] += t.not_issues
          @person_hash[t.user_id][7] += t.fix_reopen_issues
          @person_hash[t.user_id][8] += t.fixed_issues
        else
          @person_hash[t.user_id] = Array.new
          @person_hash[t.user_id] << t.investigating_issues
          @person_hash[t.user_id] << t.resolved_issues
          @person_hash[t.user_id] << t.inves_time
          @person_hash[t.user_id] << t.reopened_issues
          @person_hash[t.user_id] << t.regression_issues
          @person_hash[t.user_id] << t.found_issues
          @person_hash[t.user_id] << t.not_issues
          @person_hash[t.user_id] << t.fix_reopen_issues
          @person_hash[t.user_id] << t.fixed_issues
        end
      end

      #根据group-user的形式将项目组和成员对应存储起来，结构依然是key-array
      temp_dev_team = Hash.new
      temp_test_team = Hash.new
      team_issues.each do |t|
        #如果是测试组的人
        if t.group_type == 'test'
          if temp_test_team.include?(t.group_name)
            unless temp_test_team[t.group_name].include?(t.user_id)
              temp_test_team[t.group_name] << t.user_id
            end
          else
            temp_test_team[t.group_name] = Array.new
            temp_test_team[t.group_name] << t.user_id
          end
        #如果是其他组的人
        else
          if temp_dev_team.include?(t.group_name)
            unless temp_dev_team[t.group_name].include?(t.user_id)
              temp_dev_team[t.group_name] << t.user_id
            end
          else
            temp_dev_team[t.group_name] = Array.new
            temp_dev_team[t.group_name] << t.user_id
          end
        end
      end

      
      #构造结构key-hash(key-hash)，每个项目组对应一个由组员的issues组成的hash表
      temp_dev_team.each do |key, value|
        #@team_dev_hash[key] = Hash.new
        p_hash = Hash.new
        for v in value
          p_hash[v] = @person_hash[v]
        end
        @team_dev_hash[key] = p_hash
      end

      temp_test_team.each do |key, value|
        #@team_test_hash[key] = Hash.new
        p_hash = Hash.new
        for v in value
          p_hash[v] = @person_hash[v]
        end
        @team_test_hash[key] = p_hash
      end

      #构建哈希表存储每一个项目组的issues情况
      @team_dev_data_hash = Hash.new
      @team_test_data_hash = Hash.new

      @team_dev_hash.each do |key,value|
        @team_dev_data_hash[key] = [0,0,0,0,0]
        count = 0
        value.each do |v_key, v_value|
            count += 1
            @team_dev_data_hash[key][0] += v_value[0]
            @team_dev_data_hash[key][1] += v_value[1]
            @team_dev_data_hash[key][2] += v_value[2]
            @team_dev_data_hash[key][3] += v_value[3]
            @team_dev_data_hash[key][4] += v_value[4]
        end
        @team_dev_data_hash[key][1] = @team_dev_data_hash[key][1]/count if count != 0
        #获取该person的平均调研时间，方式是用调研的总时间除以调研的issues数
        @team_dev_data_hash[key][2] = StatisticsHelper.get_divided_number(@team_dev_data_hash[key][2], @team_dev_data_hash[key][0])
        @team_dev_data_hash[key][0] = @team_dev_data_hash[key][0]/count if count != 0
        @team_dev_data_hash[key][3] = @team_dev_data_hash[key][3]/count if count != 0
        @team_dev_data_hash[key][4] = @team_dev_data_hash[key][4]/count if count != 0
      end

      @team_test_hash.each do |key,value|
        @team_test_data_hash[key] = [0,0,0,0]
        count = 0
        value.each do |v_key, v_value|
          count += 1
            @team_test_data_hash[key][0] += v_value[5]
            @team_test_data_hash[key][1] += v_value[6]
            @team_test_data_hash[key][2] += v_value[7]
            @team_test_data_hash[key][3] += v_value[8]
        end
        @team_test_data_hash[key][0] = @team_test_data_hash[key][0]/count if count != 0
        @team_test_data_hash[key][1] = @team_test_data_hash[key][1]/count if count != 0
        @team_test_data_hash[key][2] = @team_test_data_hash[key][2]/count if count != 0
        @team_test_data_hash[key][3] = @team_test_data_hash[key][3]/count if count != 0
      end


      if request.post?
        if @chart_id == '3'
          #获得要显示的条形图内容
          observer = params[:observe_id]

          #获取图表的title
          title = "#{Project.find(params[:project_id]).name}"

          #得到记录的条数和记录的最大值
          max_value = 0
          count = @team_dev_data_hash.length
          max_value = StatisticsHelper.get_max_value(@team_dev_data_hash)

          #设置要描述的项数
          #多项
          enties = 5
          #单项
          enties_single = 1

          #获取datasource
          team_dev_data_hash_all = Hash.new
          team_dev_data_hash_inves = Hash.new
          team_dev_data_hash_resolved = Hash.new
          team_dev_data_hash_av_inves = Hash.new
          team_dev_data_hash_reopen = Hash.new
          team_dev_data_hash_regression = Hash.new

          #获取各个datasource的最大值
          inves_max_value = 0
          resolved_max_value = 0
          av_inves_max_value = 0
          reopen_max_value = 0
          regression_max_value = 0

          @team_dev_data_hash.each do |key,value|
            team_dev_data_hash_all[key] = [value[0], value[1], value[2], value[3], value[4]]
            team_dev_data_hash_inves[key] = [value[0]]
            inves_max_value = value[0] if value[0] > inves_max_value
            team_dev_data_hash_resolved[key] = [value[1]]
            resolved_max_value = value[1] if value[1] > resolved_max_value
            team_dev_data_hash_av_inves[key] = [value[2]]
            av_inves_max_value = value[2] if value[2] > av_inves_max_value
            team_dev_data_hash_reopen[key] = [value[3]]
            reopen_max_value = value[3] if value[3] > reopen_max_value
            team_dev_data_hash_regression[key] = [value[4]]
            regression_max_value = value[4] if value[4] > regression_max_value
          end

          #显示所有项的对比
          if observer == 'all'
            y_labels = ["regression", "reopened", "av_inves time", "resolved", "inves"]
            x_range = [0,max_value]

            bar_chart = Chart.new(title, 'bar_chart', team_dev_data_hash_all, 700, 400)
            bar_chart.set_bar_width(count, enties, enties*count)
            bar_chart.generate_y_labels(y_labels)
            bar_chart.generate_x_range(x_range)
            @bar_chart = bar_chart.to_url
            #显示其他各项对比
            elsif observer == '1'
              bar_chart = Chart.new(title, 'bar_chart', team_dev_data_hash_inves, 700, 400)
              bar_chart.set_bar_width(count, enties_single, count)
              bar_chart.generate_y_labels(["inves"])
              bar_chart.generate_x_range([0, inves_max_value])
              @bar_chart = bar_chart.to_url

            elsif observer == '2'
              bar_chart = Chart.new(title, 'bar_chart', team_dev_data_hash_resolved, 700, 400)
              bar_chart.set_bar_width(count, enties_single, count)
              bar_chart.generate_y_labels(["resolved"])
              bar_chart.generate_x_range([0, resolved_max_value])
              @bar_chart = bar_chart.to_url

            elsif observer == '3'
              bar_chart = Chart.new(title, 'bar_chart', team_dev_data_hash_av_inves, 700, 400)
              bar_chart.set_bar_width(count, enties_single, count)
              bar_chart.generate_y_labels(["av_inves"])
              bar_chart.generate_x_range([0, av_inves_max_value])
              @bar_chart = bar_chart.to_url

            elsif observer == '4'
              bar_chart = Chart.new(title, 'bar_chart', team_dev_data_hash_reopen, 700, 400)
              bar_chart.set_bar_width(count, enties_single, count)
              bar_chart.generate_y_labels(["reopened"])
              bar_chart.generate_x_range([0, reopen_max_value])
              @bar_chart = bar_chart.to_url

            elsif observer == '5'
              bar_chart = Chart.new(title, 'bar_chart', team_dev_data_hash_regression, 700, 400)
              bar_chart.set_bar_width(count, enties_single, count)
              bar_chart.generate_y_labels(["regression"])
              bar_chart.generate_x_range([0, regression_max_value])
              @bar_chart = bar_chart.to_url

          end
        elsif @chart_id == '4'
          observer = params[:observe_id]

          title = "#{Project.find(params[:project_id]).name}"

          max_value = 0
          count = @team_test_data_hash.length
          max_value = StatisticsHelper.get_max_value(@team_test_data_hash)

          #设置项数
          enties = 4
          enties_single = 1

          #存储datasource
          team_test_data_hash_all = Hash.new
          team_test_data_hash_found = Hash.new
          team_test_data_hash_not_issues = Hash.new
          team_test_data_hash_fix_reopen = Hash.new
          team_test_data_hash_fixed = Hash.new

          #存储各个datasource的最大值
          found_max_value = 0
          not_issues_max_value = 0
          fix_reopen_max_value = 0
          fixed_max_value = 0

          #获取datasource和他们的最大值
          @team_test_data_hash.each do |key, value|
            team_test_data_hash_all[key] = [value[0], value[1], value[2], value[3]]
            team_test_data_hash_found[key] = [value[0]]
            found_max_value = value[0] if value[0] > found_max_value
            team_test_data_hash_not_issues[key] = [value[1]]
            not_issues_max_value = value[1] if value[1] > not_issues_max_value
            team_test_data_hash_fix_reopen = [value[2]]
            fix_reopen_max_value = value[2] if value[2] > fix_reopen_max_value
            team_test_data_hash_fixed[key] = [value[3]]
            fixed_max_value = value[3] if value[3] > fixed_max_value
          end

          if observer == 'all'
            bar_chart= Chart.new(title, 'bar_chart', team_test_data_hash_all, 700, 400)
            bar_chart.set_bar_width(count,enties,count*enties)
            bar_chart.generate_y_labels(["fixed", "fix reopen", "not issues", "found"])
            bar_chart.generate_x_range([0, max_value])

            @bar_chart = bar_chart.to_url

          elsif observer == '6'
            bar_chart= Chart.new(title, 'bar_chart', team_test_data_hash_found, 700, 400)
            bar_chart.set_bar_width(count,enties_single,count)
            bar_chart.generate_y_labels( ["found"])
            bar_chart.generate_x_range([0, found_max_value])

            @bar_chart = bar_chart.to_url
          elsif observer == '7'
            bar_chart= Chart.new(title, 'bar_chart', team_test_data_hash_not_issues, 700, 400)
            bar_chart.set_bar_width(count,enties_single,count)
            bar_chart.generate_y_labels(["not issues"])
            bar_chart.generate_x_range([0, not_issues_max_value])

            @bar_chart = bar_chart.to_url
          elsif observer == '8'
            bar_chart= Chart.new(title, 'bar_chart', team_test_data_hash_fix_reopen, 700, 400)
            bar_chart.set_bar_width(count,enties_single,count)
            bar_chart.generate_y_labels(["fix reopen"])
            bar_chart.generate_x_range([0, fix_reopen_max_value])

            @bar_chart = bar_chart.to_url
          elsif observer == '9'
            bar_chart= Chart.new(title, 'bar_chart', team_test_data_hash_fixed, 700, 400)
            bar_chart.set_bar_width(count,enties_single,count)
            bar_chart.generate_y_labels(["fixed"])
            bar_chart.generate_x_range([0, fixed_max_value])

            @bar_chart = bar_chart.to_url
          end
        elsif @chart_id == '5' or @chart_id == '6'
          count = 0
          @person_hash.each do |key, value|
            count += 1
            #investigating issues
            @group_total[0] += value[0]
            #resolved issues
            @group_total[1] += value[1]
            #inves time
            @group_total[2] += value[2]
            #reopened issues
            @group_total[3] += value[3]
            #regression issues
            @group_total[4] += value[4]
            #found issues
            @group_total[5] += value[5]
            #not a bug issues
            @group_total[6] += value[6]
            #fix reopened issues
            @group_total[7] += value[7]
            #fixed issues
            @group_total[8] += value[8]
          end
          if count != 0
            @group_total[1] = @group_total[1]/count
            @group_total[2] = StatisticsHelper.get_divided_number(@group_total[2], @group_total[0])
            @group_total[0] = @group_total[0]/count
            @group_total[3] = @group_total[3]/count
            @group_total[4] = @group_total[4]/count
            @group_total[5] = @group_total[5]/count
            @group_total[6] = @group_total[6]/count
            @group_total[7] = @group_total[7]/count
            @group_total[8] = @group_total[8]/count
          end
        end
      end
    end
  end
end