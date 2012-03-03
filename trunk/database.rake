require 'active_record'

#任务的命名空间
namespace :statistics do
  #定义各个状态的值
  #新建状态
  FOUND = '1'
  #进行中
  ONGOING = '2'
  #已解决
  RESOLVED = '3'
  #调研中
  INVESTIGATING = '17'
  #测试通过
  FIXED = '7'
  #已关闭
  CLOSED = '5'
  #重新打开
  REOPEN = '4'
  #已拒绝
  NOTABUG = '6'

  #测试人员角色名
  TEST_ROLE_NAME = '测试人员'

  TODAY = Date.today
  YESTERDAY = Date.today - 1

  #得到utc时间
  def get_utc_date
    now = Time.now
    utc = now.gmtime
    str_today = utc.strftime("%Y-%m-%d")
    return Date.parse(str_today)
  end
  #计算该问题的类别
  def find_category(id)
    #如果参数为空
    if id == nil
      return 1
    #如果参数不为空
    else
      custom_value = CustomValue.find(:first, :conditions => {:customized_id => id, :value => 'Regression'})
      if custom_value != nil
        return 2
      else
        return 3
      end
    end
  end

  #得到该issue的某次符合条件的更新时间
  def find_update_time(id, prop_key, old_value, value, flag)
    issue_journals = Journal.find(:all, :conditions => {:journalized_id => id})

    issue_journals.each do |issue_journal|
      journal_details = JournalDetail.find(:all, :conditions => {:journal_id => issue_journal.id})
       journal_details.each do |journal_detail|
        if flag == 1
            if journal_detail.old_value == old_value and journal_detail.value == value
              return issue_journal.created_on
            end
          #从某个状态撤离
          elsif flag == 2
            if journal_detail.old_value == old_value
              return issue_journal.created_on
            end
          #进入某个状态
          elsif flag == 3
            if journal_detail.value == value
              return issue_journal.created_on
            end
          end if journal_detail.prop_key == prop_key
      end
    end
    return -1
  end

  #根据给定的人员id和项目id计算该成员在该项目中所属的组别
  def find_group(u_id, p_id)
    #存储人员的组信息
    mul_group = Hash.new
    #找到该人员的所有所属组
    groups = User.find(u_id).groups
    #如果该成员未被分在任何组内
    if groups.empty?
      mul_group['group_id'] = nil
      mul_group['group_name'] = 'OTHER'
      mul_group['group_type'] = 'none'
    else
      #对于每个组，查询本组所属的所有项目
      groups.each do |group|
        group_members = Member.find(:all, :conditions => {:user_id => group.id})
        #如果该组不隶属于任何项目
        if group_members.empty?
          mul_group['group_id'] = nil
          mul_group['group_name'] = 'OTHER'
          mul_group['group_type'] = 'no projects'
        else
          #循环查找是否存在当前项目
          group_members.each do |g_member|
            if g_member.project_id == p_id
              mul_group['group_id'] = group.id
              break
            end
          end
          if mul_group['group_id'] != nil
            user_role = MemberRole.find(:first, :conditions => {:member_id => (Member.find(:first, :conditions => {:project_id => p_id, :user_id => u_id}))})
            #查找该项目下该成员是否是测试人员
            if Role.find(user_role.role_id).name == TEST_ROLE_NAME
              mul_group['group_type'] = 'test'
            else
              mul_group['group_type'] = 'dev'
            end
            mul_group['group_name'] = Group.find(mul_group['group_id']).to_s
          else
            mul_group['group_name'] = 'OTHER'
            mul_group['group_type'] = 'no such project'
          end
        end
      end
    end
    return mul_group
  end

  #rake任务，从数据库中抓取数据，得到表active_issues
  desc "generate data for active_issues table every day"
  task :generate_active_issues_table => :environment do
    #得到所有的项目和优先级和tracker类别
    projects = Project.find(:all)
    versions = Version.find(:all)
    priorities = Enumeration.find(:all,:conditions => {:type => 'IssuePriority'})
    trackers = Tracker.find(:all)

    #分类别对他们进行统计并存入数据库
    trackers.each do |tracker|
      projects.each do |project|
        versions.each do |version|
          priorities.each do |priority|
            issues = Issue.find(:all,
                                :include => [:status],
                                :conditions => ["issue_statuses.is_closed = '0' and issues.tracker_id = ? and issues.project_id = ? and issues.fixed_version_id = ? and issues.priority_id =?", tracker.id, project.id, version.id, priority.id])
            unless issues.empty?
              puts "now is building tracker: #{tracker.id}, project: #{project.id}, version: #{version.id} priority: #{priority.id} "
              active_issue = ActiveIssue.new_normal
              issues_number = issues.count
              active_issue.project_id = project.id
              active_issue.project_name = project.name
              active_issue.version_id = version.id
              active_issue.version_name = version.name
              active_issue.issues_number = issues_number
              active_issue.tracker_id = tracker.id
              active_issue.tracker_name = tracker.name
              active_issue.priority_id = priority.id
              active_issue.priority_name = priority.name

              #存入数据库
              active_issue.save
            end
          end
        end
      end
    end

    conditions = Hash.new

    trackers.each do |tracker|
      projects.each do |project|
        priorities.each do |priority|
          conditions["issue_statuses.is_closed"] = '0'
          conditions["issues.tracker_id"] = tracker.id
          conditions["issues.project_id"] = project.id
          conditions["issues.fixed_version_id"] = nil
          conditions["issues.priority_id"] = priority.id
          issues = Issue.find(:all,
                              :include => [:status],
                              :conditions => conditions)
          unless issues.empty?
            puts "now is building tracker: #{tracker.id}, project: #{project.id}, priority: #{priority.id} no target version"
            active_issue = ActiveIssue.new_normal
            issues_number = issues.count
            active_issue.project_id = project.id
            active_issue.project_name = project.name
            active_issue.issues_number = issues_number
            active_issue.tracker_id = tracker.id
            active_issue.tracker_name = tracker.name
            active_issue.priority_id = priority.id
            active_issue.priority_name = priority.name

            #存入数据库
            active_issue.save
          end
        end
      end
    end

  end
  #rake 任务1结束

  #rake任务，从数据库中抓取数据以获取表team_issues
  desc "generate data for team_issues"
  task :generate_team_issues_table => :environment do

    #get date of today
    today = TODAY
    #get date of yesterday
    yesterday = YESTERDAY

    puts "today is #{today.to_s}, get the data of yesterday #{yesterday.to_s}"

    #get all projects
    projects = Project.find(:all)                                               
    puts "projects number #{projects.count} total"

    #遍历所有的项目
    projects.each do |project|
      puts "enter project #{project.id}..."
      #获取在昨天更新的所有issues
      issues = Issue.find(:all, :conditions => {:project_id => project.id, :updated_on => (yesterday..today)})
      #获取在昨天创建的所有issues
      issues_created = Issue.find(:all, :conditions => {:project_id => project.id, :created_on => (yesterday..today)})

      #保存该项目下该同学是否被记录，哈希结构key-array
      users = Hash.new
      users[project.id] = Array.new

      puts "created issues number #{issues_created.count} total"
      issues_created.each do |issue_created|
        puts "issue id #{issue_created.id}"
        #如果该人员今天被统计过
        if users[project.id].include?(issue_created.author_id)                  
          to_update_team_issue = TeamIssue.find(:first, :conditions => {:user_id => issue_created.author_id, :project_id => project.id, :created_on => today})

          puts "update user_id #{issue_created.author_id}, project #{project.id}"

          to_update_team_issue.found_issues += 1
          to_update_team_issue.save

          update_category = find_category(issue_created.id)

          if update_category == 2
            #寻找到是who?Resolved的该issue
            update_regression_user_id = nil                                     

            #该类型issue新建时必须指定关联issue，即因为是哪个issue引起的
            update_issue_to = IssueRelation.find(:first, :conditions => {:issue_from_id => issue_created.id}).issue_to_id
            if update_issue_to != nil
              #得到被关联的issue
              update_regression_issue = Issue.find(:first, :conditions => {:id => update_issue_to})
              #获取该issue的所有更新记录
              update_regression_journals = Journal.find(:all, :conditions => {:journalized_id => update_issue_to})
              unless update_regression_journals.empty?
                update_regression_journals.each do |ur|
                  #查到了将该issue改成RESOLVED的人
                  update_regression_journal_detail = JournalDetail.find(:last, :conditions => {:prop_key => 'status_id', :value => RESOLVED, :journal_id => ur.id})
                  if update_regression_journal_detail != nil
                    #抓住他了
                    update_regression_user_id = ur.user_id
                    break
                  end
                end
              end

              update_regression_project_id = project.id
              if update_regression_user_id != nil
                #如果被关联的issue不是当前project的
                if update_regression_issue.project_id != project.id
                  #获取他自己所属的project
                  update_regression_project_id = update_regression_issue.project_id
                  #建立自己的成员hash
                  users[update_regression_project_id] = Array.new
                end
                #如果今天该人员被统计过
                if users[update_regression_project_id].include?(update_regression_user_id)
                  #获取今天的记录
                  to_update_regression_team_issue = TeamIssue.find(:first, :conditions => {:user_id => update_regression_user_id, :project_id => update_regression_project_id, :created_on => today})

                  puts "update user #{update_regression_user_id}, project #{project.id}"
                  to_update_regression_team_issue.regression_issues += 1

                  to_update_regression_team_issue.save
                #如果没有被统计过
                else
                  #今天被统计过了
                  users[update_regression_project_id] << update_regression_user_id

                  update_regression_m_group = find_group(update_regression_user_id, update_regression_project_id)
                  #新建记录，准备存储
                  a_team_issue = TeamIssue.new_advance

                  puts "create user #{update_regression_user_id} project #{update_regression_project_id}"

                  a_team_issue.project_name = Project.find(update_regression_project_id).name
                  a_team_issue.user_id = update_regression_user_id
                  a_team_issue.dev_name = User.find(update_regression_user_id).name
                  a_team_issue.project_id = update_regression_project_id
                  a_team_issue.version_id = update_regression_issue.fixed_version_id
                  a_team_issue.version_id = Version.find(:first, :conditions => {:id => update_regression_issue.fixed_version_id}).name  if update_regression_issue.fixed_version_id != nil
                  a_team_issue.group_type = update_regression_m_group['group_type']
                  a_team_issue.group_id = update_regression_m_group['group_id']
                  a_team_issue.group_name = update_regression_m_group['group_name']

                  a_team_issue.regression_issues = 1

                  a_team_issue.save
                end
              end
            else
              puts "related issue doesn't exist!"
            end
          end
        #如果还没有被统计
        else                                                                    
          users[project.id] << issue_created.author_id                          

          m_group = find_group(issue_created.author_id, project.id)

          a_team_issue = TeamIssue.new_advance                                  

          a_team_issue.project_name = project.name
          a_team_issue.user_id = issue_created.author_id
          a_team_issue.dev_name = User.find(issue_created.author_id).name
          a_team_issue.project_id = project.id
          a_team_issue.version_id = issue_created.fixed_version_id
          a_team_issue.version_name = Version.find(:first, :conditions => {:id => issue_created.fixed_version_id}).name  if issue_created.fixed_version_id != nil
          a_team_issue.group_id = m_group['group_id']
          a_team_issue.group_name = m_group['group_name']
          a_team_issue.found_issues += 1
          a_team_issue.save
          puts "create user #{issue_created.author_id} project #{project.id}"

          category = find_category(issue_created.id)
          #如果该新建类别为regression
          if category == 2                                                      
            regression_user_id = nil
            issue_to = IssueRelation.find(:first, :conditions => {:issue_from_id => issue_created.id}).issue_to_id
            if issue_to != nil
              regression_issue = Issue.find(:first, :conditions => {:id => issue_to})
              regression_journals = Journal.find(:all, :conditions => {:journalized_id => issue_to})
              unless regression_journals.empty?
                regression_journals.each do |r|
                  regression_journal_detail = JournalDetail.find(:first, :conditions => {:prop_key => 'status_id', :value => RESOLVED, :journal_id => r.id})
                  if regression_journal_detail != nil
                    regression_user_id = r.user_id
                    break
                  end
                end
              end

              regression_project_id = project.id
              if regression_user_id != nil
                if regression_issue.project_id != project.id
                  regression_project_id = regression_issue.project_id
                  users[regression_project_id] = Array.new
                end
                if users[regression_project_id].include?(regression_user_id)
                  to_update_team_issue = TeamIssue.find(:first, :conditions => {:user_id => regression_user_id, :project_id => regression_project_id, :created_on => today})

                  puts "update user #{regression_user_id} project #{regression_project_id}"

                  to_update_team_issue.regression_issues += 1
                  to_update_team_issue.save
                else
                  users[regression_project_id] << regression_user_id
                  regression_m_group = find_group(regression_user_id, regression_issue.project_id)

                  a_team_issue = TeamIssue.new_advance                              #new team_issue

                  puts "created user #{regression_user_id} project #{regression_issue.project_id}"

                  a_team_issue.project_name = Project.find(regression_issue.project_id).name
                  a_team_issue.user_id = regression_user_id
                  a_team_issue.dev_name = User.find(regression_user_id).name
                  a_team_issue.project_id = regression_issue.project_id
                  a_team_issue.version_id = regression_issue.fixed_version_id
                  a_team_issue.version_name = Version.find(:first, :conditions => {:id => regression_issue.fixed_version_id}).name if regression_issue.fixed_version_id != nil
                  a_team_issue.group_type = regression_m_group['group_type']
                  a_team_issue.group_id = regression_m_group['group_id']
                  a_team_issue.group_name = regression_m_group['group_name']

                  #regression bug 数置 1
                  a_team_issue.regression_issues += 1                           

                  #保存至数据库
                  a_team_issue.save                                             
                end
              end
            else
              puts "related issue doesn't exist!"
            end
          end  
        end
      end
      
      puts "updated issues number #{issues.count} total"
      issues.each do |issue|
        puts "issue id #{issue.id}"
        #得到该issue今天所有的更新
        issue_all_journals = Journal.find(:all, :order => 'created_on DESC', :conditions => {:journalized_id => issue.id, :created_on => (yesterday..today)})
        puts "issue journals number #{issue_all_journals.count} total"        
        unless issue_all_journals.empty?                                        
          puts "enter journals status..."
          issue_all_journals.each do |issue_journal|
            issue_journal_details = JournalDetail.find(:all, :conditions => {:journal_id => issue_journal.id})
            issue_journal_details.each do |issue_journal_detail|
              issue_prop_key = issue_journal_detail.prop_key
              if issue_prop_key == 'status_id'
                #如果更新是撤离investigating状态
                if issue_journal_detail.old_value == INVESTIGATING                        
                  puts "get away from invesgating..."
                  #正是此人将状态更改的
                  user_id = issue_journal.user_id                               
                  #下面计算他调研该问题所花费的时间
                  #获取该次更新时的时间
                  update_time = issue_journal.created_on
                  update_inves_time = find_update_time(issue.id, 'status_id', '', INVESTIGATING, 3)
                  assigned_to_time = nil
                  inves_time = nil
                  inves_project_id = project.id
                  if update_inves_time != -1
                    #计算在调研的过程中指派人有没有更改
                    judge_journals = Journal.find(:all, :order => 'created_on', :conditions => {:journalized_id => issue.id, :created_on => (update_inves_time..update_time)})
                    judge_journals.each do |judge_journal|
                      judge_journal_details = JournalDetail.find(:last, :conditions => {:prop_key => 'assigned_to_id', :value => user_id} )
                      if judge_journal_details != nil
                        puts "assiged people has ever changed!"
                        assigned_to_time = judge_journal.created_on
                        break
                      end
                    end
                    if assigned_to_time != nil
                      #调研时间以分钟为单位
                      inves_time = ((update_time.to_i - assigned_to_time.to_i)/60.0).to_i           
                    else
                      inves_time = ((update_time.to_i - update_inves_time.to_i)/60.0).to_i
                    end

                    #计算是否是在其他项目下investigating的
                    journal_at_update_time = Journal.find(:first, :conditions => {:journalized_id => issue.id, :created_on => update_time})
                    other_project_inves = JournalDetail.find(:first, :conditions => {:prop_key => 'project_id', :journal_id => journal_at_update_time.id})

                    if other_project_inves != nil and other_project_inves.value != (project.id).to_s
                      users[other_project_inves.value.to_i] = Array.new
                      inves_project_id = other_project_inves.value.to_i
                      puts "project id has ever changed!"
                    end

                    investigated_m_group = find_group(user_id, inves_project_id)
                   
                    if users[inves_project_id].include?(user_id)
                      to_update_team_issue = TeamIssue.find(:first, :conditions => {:user_id => user_id, :project_id => inves_project_id, :created_on => today})

                      puts "update user #{user_id} project #{inves_project_id}"
                      
                      to_update_team_issue.investigating_issues += 1
                      to_update_team_issue.inves_time += inves_time

                      to_update_team_issue.save
                    else
                      users[inves_project_id] << user_id
                      a_team_issue = TeamIssue.new_advance                            

                      puts "create user #{user_id} project #{inves_project_id}"

                      a_team_issue.project_name = Project.find(inves_project_id).name
                      a_team_issue.project_id = inves_project_id
                      a_team_issue.version_id = issue.fixed_version_id
                      a_team_issue.version_name = Version.find(:first, :conditions => {:id => issue.fixed_version_id}).name if issue.fixed_version_id != nil
                      a_team_issue.user_id = user_id
                      a_team_issue.dev_name = User.find(user_id).name

                      a_team_issue.group_type = investigated_m_group['group_type']
                      a_team_issue.group_id = investigated_m_group['group_id']
                      a_team_issue.group_name = investigated_m_group['group_name']

                      a_team_issue.investigating_issues += 1
                      a_team_issue.inves_time += inves_time

                      a_team_issue.save
                    end
                  else
                    puts "error occured! can not find invesgating status"
                  end
                #该issue的状态被更新为已解决,该版本无法处理Resolved后将project更改的情况
                elsif issue_journal_detail.value == RESOLVED                         
                  puts "enter resolved status ..."
                  user_id = issue_journal.user_id                               

                  if users[project.id].include?(user_id)
                    to_update_team_issue = TeamIssue.find(:first, :conditions => {:user_id => user_id, :project_id => project.id, :created_on => today})

                    puts "update user #{user_id} project #{project.id}"
                    to_update_team_issue.resolved_issues += 1
                    to_update_team_issue.save
                  else
                    users[project.id] << user_id
                    a_team_issue = TeamIssue.new_advance                         

                    puts "create user #{user_id} project #{project.id}"

                    resolved_m_group = find_group(user_id, project.id)
                    a_team_issue.project_name = project.name
                    a_team_issue.project_id = project.id
                    a_team_issue.version_id = issue.fixed_version_id
                    a_team_issue.version_name = Version.find(:first, :conditions => {:id => issue.fixed_version_id}).name if issue.fixed_version_id != nil
                    a_team_issue.user_id = user_id
                    a_team_issue.dev_name = User.find(user_id).name

                    a_team_issue.group_type = resolved_m_group['group_type']
                    a_team_issue.group_id = resolved_m_group['group_id']
                    a_team_issue.group_name = resolved_m_group['group_name']

                    a_team_issue.resolved_issues += 1
                    a_team_issue.save
                    
                  end
                #如果此更新将issue的状态更新为重新打开
                elsif issue_journal_detail.value == REOPEN                      
                  puts "enter reopen status..."
                  user_id = nil
                  #开发人员的责任 reopen
                  if issue_journal_detail.old_value == RESOLVED                      
                    puts "dev's responsibility for reopen issue"
                    #下面寻找是who?Resolved了这个issue
                    reopen_journals = Journal.find(:all, :conditions => {:journalized_id => issue.id})
                    unless reopen_journals.empty?
                      reopen_journals.each do |rj|
                        #获取最近把issue更改成RESOLVED的淫
                        reopen_journal_details = JournalDetail.find(:last, :conditions => {:prop_key => 'status_id', :value => RESOLVED, :journal_id => rj.id})
                        if reopen_journal_details != nil
                          user_id = rj.user_id
                        end
                      end
                    end
                    if user_id != nil
                      if users[project.id].include?(user_id)
                        to_update_team_issue = TeamIssue.find(:first, :conditions => {:user_id => user_id, :project_id => project.id, :created_on => today})

                        puts "update user #{user_id} project #{project.id}"
                        to_update_team_issue.reopened_issues += 1
                        to_update_team_issue.save
                      else
                        users[project.id] << user_id
                        a_team_issue = TeamIssue.new_advance                    

                        reopen_m_group = find_group(user_id, project.id)
                        a_team_issue.project_name = project.name
                        a_team_issue.project_id = project.id
                        a_team_issue.version_id = issue.fixed_version_id
                        a_team_issue.version_name = Version.find(:first, :conditions => {:id => issue.fixed_version_id}).name if issue.fixed_version_id != nil
                        a_team_issue.user_id = user_id
                        a_team_issue.dev_name = User.find(user_id).name

                        a_team_issue.group_type = reopen_m_group['group_type']
                        a_team_issue.group_id = reopen_m_group['group_id']
                        a_team_issue.group_name = reopen_m_group['group_name']

                        a_team_issue.reopened_issues += 1
                        a_team_issue.save

                      end
                    end
                  #测试人员的责任 fix_reopen
                  elsif issue_journal_detail.old_value == FIXED                 
                    puts "test people's responsibility for reopened issue"
                    reopen_journals = Journal.find(:all, :conditions => {:journalized_id => issue.id})
                    unless reopen_journals.empty?
                      reopen_journals.each do |rj|
                        #捉住最后将该issue更改为测试通过的人
                        reopen_journal_details = JournalDetail.find(:last, :conditions => {:prop_key => 'status_id', :value => FIXED, :journal_id => rj.id})
                        if reopen_journal_details != nil
                          user_id = rj.user_id
                        end
                      end
                    end
                    if user_id != nil
                      if users[project.id].include?(user_id)
                        to_update_team_issue = TeamIssue.find(:first, :conditions => {:user_id => user_id, :project_id => project.id, :created_on => today})

                        to_update_team_issue.fix_reopen_issues += 1
                        to_update_team_issue.save
                      else
                        users[project.id] << user_id
                        a_team_issue = TeamIssue.new_advance                        

                        fix_reopen_m_group = find_group(user_id, project.id)
                        a_team_issue.project_name = project.name
                        a_team_issue.project_id = project.id
                        a_team_issue.version_id = issue.fixed_version_id
                        a_team_issue.version_name = Version.find(:first, :conditions => {:id => issue.fixed_version_id}).name if issue.fixed_version_id != nil
                        a_team_issue.user_id = user_id
                        a_team_issue.dev_name = User.find(user_id).name

                        a_team_issue.group_type = fix_reopen_m_group['group_type']
                        a_team_issue.group_id = fix_reopen_m_group['group_id']
                        a_team_issue.group_name = fix_reopen_m_group['group_name']

                        a_team_issue.fix_reopen_issues += 1
                        a_team_issue.save
                      end
                    end
                  end
                elsif issue_journal_detail.value == FIXED
                  puts "enter fixed status..."
                  #该版本无法处理fix测试通过后将project更改的情况
                  user_id = issue_journal.user_id                               

                  if users[project.id].include?(user_id)
                    to_update_team_issue = TeamIssue.find(:first, :conditions => {:user_id => user_id, :project_id => project.id, :created_on => today})

                    puts "update user #{user_id} project #{project.id}"
                    to_update_team_issue.fixed_issues += 1
                    to_update_team_issue.save
                  else
                    users[project.id] << user_id
                    a_team_issue = TeamIssue.new_advance                                                

                    puts "create user #{user_id} project #{project.id}"
                    
                    fixed_m_group = find_group(user_id, project.id)
                    a_team_issue.project_name = project.name
                    a_team_issue.project_id = project.id
                    a_team_issue.version_id = issue.fixed_version_id
                    a_team_issue.version_name = Version.find(:first, :conditions => {:id => issue.fixed_version_id}).name if issue.fixed_version_id != nil
                    a_team_issue.user_id = user_id
                    a_team_issue.dev_name = User.find(user_id).name

                    a_team_issue.group_type = fixed_m_group['group_type']
                    a_team_issue.group_id = fixed_m_group['group_id']
                    a_team_issue.group_name = fixed_m_group['group_name']

                    a_team_issue.fixed_issues += 1
                    a_team_issue.save

                  end
                #如果更新后状态为closed，查看bug的类型
                elsif issue_journal_detail.value == NOTABUG
                  puts "enter not a bug status..."                           
                  #新建这个bug的作者抓获
                  user_id = issue.author_id
                  #TODO 查出是谁新建了这个bug

                  if users[project.id].include?(user_id)
                    to_update_team_issue = TeamIssue.find(:first, :conditions => {:user_id => user_id, :project_id => project.id, :created_on => today})

                    puts "update user #{user_id} project #{project.id}"
                    to_update_team_issue.not_issues += 1
                    to_update_team_issue.save
                  else
                    users[project.id] << user_id
                    a_team_issue = TeamIssue.new_advance

                    puts "create user #{user_id} project #{project.id}"

                    closed_m_group = find_group(user_id, project.id)
                    a_team_issue.project_name = project.name
                    a_team_issue.project_id = project.id
                    a_team_issue.version_id = issue.fixed_version_id
                    a_team_issue.version_name = Version.find(:first, :conditions => {:id => issue.fixed_version_id}).name if issue.fixed_version_id != nil
                    a_team_issue.user_id = user_id
                    a_team_issue.dev_name = User.find(user_id).name

                    a_team_issue.group_type = closed_m_group['group_type']
                    a_team_issue.group_id = closed_m_group['group_id']
                    a_team_issue.group_name = closed_m_group['group_name']

                    a_team_issue.not_issues += 1
                    a_team_issue.save
                  end
                    
                end
              elsif issue_prop_key == 'assigned_to_id'
                #如果指派人更改，并且当前状态为invesgating，计算停留在该指派人头上的时间
                puts "enter propkey assigned_to_id changed..."
                #得到当前的issue号
                issue_id = issue.id                                             
                user_from_id = issue_journal_detail.old_value
                user_id = user_from_id.to_i

                start_assigned_time = nil
                update_assigned_time = issue_journal.created_on

                start_inves_time = nil
                finish_inves_time = nil
                
                journals_before_assigned = Journal.find(:all, :conditions => ["journalized_id = ? and created_on <= ?", issue_id, update_assigned_time])

                journals_before_assigned.each do |journal_before_assigned|
                  journal_details_before_assigned = JournalDetail.find(:all, :conditions => {:journal_id => journal_before_assigned.id, :prop_key => 'status_id'})

                  journal_details_before_assigned.each do |jd|
                    #开始调研
                    if jd.value == INVESTIGATING
                      start_inves_time = journal_before_assigned.created_on
                    end
                    #结束调研
                    if jd.old_value == INVESTIGATING
                      finish_inves_time = journal_before_assigned.created_on
                    end
                  end
                end

                assigned_project_id = project.id
                #如果当前处于inves状态
                if start_inves_time != nil and finish_inves_time == nil        
                  journals_duration_inves = Journal.find(:all, :conditions => {:journalized_id => issue.id, :created_on => (start_inves_time..update_assigned_time)})
                  journals_duration_inves.each do |journal_duration_inves|
                    journal_details_duration_inves = JournalDetail.find(:all, :conditions => {:journal_id => journal_duration_inves.id})
                    journal_details_duration_inves.each do |journal_detail_duration_inves|
                      if journal_detail_duration_inves.prop_key == 'project_id' and journal_detail_duration_inves.prop_key != (project.id).to_s
                        assigned_project_id = (journal_detail_duration_inves.value).to_i
                        users[assigned_project_id] = Array.new
                      end
                      if journal_detail_duration_inves.prop_key == 'assigned_to_id' and journal_detail_duration_inves.value == user_from_id
                        puts "find assigned changed from user"
                        start_assigned_time = journal_duration_inves.created_on
                      end
                    end
                  end
                end

                if start_assigned_time != nil
                  inves_time = ((update_assigned_time.to_i - start_assigned_time.to_i)/60.0).to_i
                  if users[assigned_project_id].include?(user_id)
                    to_update_team_issue = TeamIssue.find(:first, :conditions => {:user_id => user_id, :project_id => assigned_project_id, :created_on => today})
                    
                    puts "update user #{user_id} project #{assigned_project_id}"
                    to_update_team_issue.inves_time += inves_time
                    to_update_team_issue.save
                  else
                    users[assigned_project_id] << user_id
                    a_team_issue = TeamIssue.new_advance                         

                    puts "create user #{user_id} project #{assigned_project_id}"

                    assigned_m_group = find_group(user_id, assigned_project_id)
                    a_team_issue.project_name = Project.find(assigned_project_id).name
                    a_team_issue.project_id = assigned_project_id
                    a_team_issue.version_id = issue.fixed_version_id
                    a_team_issue.version_name = Version.find(:first, :conditions => {:id => issue.fixed_version_id}).name if issue.fixed_version_id != nil
                    a_team_issue.user_id = user_id
                    a_team_issue.dev_name = User.find(user_id).name

                    a_team_issue.group_type = assigned_m_group['group_type']
                    a_team_issue.group_name = assigned_m_group['group_name']
                    a_team_issue.group_id = assigned_m_group['group_id']

                    a_team_issue.inves_time += inves_time
                    a_team_issue.save
                  end
                end
              end
            end
          end
        end
      end     
    end    
  end

  desc "generate data for personal priority issues"
  task :generate_personal_priority_issues_table => :environment do
    #该任务用来生成表personal_priority_issues
    #根据优先级获取今天更新的所有issue并且跟踪每个issue在今天的所有更新
    #将每条记录通过分析和计算后存入数据库
    
    today = TODAY
    yesterday = YESTERDAY

    puts "generate data for personal priority issues today #{today.to_s} and yesterday #{yesterday.to_s}"
    #获取所有的优先级
    priorities = Enumeration.find(:all, :conditions => {:type => 'IssuePriority'})

    puts "priorities number #{priorities.count} total"
    priorities.each do |priority|
      puts "enter priority #{priority.id}..."
      issues = Issue.find(:all, :conditions => {:priority_id => priority.id, :updated_on => (yesterday..today)})
      issues_created = Issue.find(:all, :conditions => {:priority_id => priority.id, :created_on => (yesterday..today)})

      #保存该优先级下该同学是否被记录
      #注:优先级以当前最新状态为准
      users = Hash.new
      users[priority.id] = Array.new

      puts "created issues number #{issues_created.count} total"

      issues_created.each do |issue_created|
        #此状态为issue的初始状态，即新建...
        #如果该人员今天被统计过
        if users[priority.id].include?(issue_created.author_id)                 
          to_update_issue_10 = PersonalPriorityIssue.find(:first, :conditions => {:user_id => issue_created.author_id, :priority_id => priority.id, :created_on => today})

          puts "update user_id #{issue_created.author_id}, priority #{priority.id}"

          update_category = find_category(issue_created.id)

          if update_category == 2
            #寻找到是who?Resolved的该issue
            update_regression_user_id = nil                                     
            #该类型issue新建时必须制定关联issue，即因为是哪个issue引起的
            update_issue_to = IssueRelation.find(:first, :conditions => {:issue_from_id => issue_created.id}).issue_to_id
            if update_issue_to != nil
              update_regression_issue = Issue.find(:first, :conditions => {:id => update_issue_to})
              update_regression_journals = Journal.find(:all, :conditions => {:journalized_id => update_issue_to})
              unless update_regression_journals.empty?
                update_regression_journals.each do |ur|
                  update_regression_journal_detail = JournalDetail.find(:last, :conditions => {:prop_key => 'status_id', :value => RESOLVED, :journal_id => ur.id})
                  if update_regression_journal_detail != nil
                    update_regression_user_id = ur.user_id
                    break
                  end
                end
              end

              update_regression_priority_id = priority.id
              if update_regression_user_id != nil
                if update_regression_issue.priority_id != priority.id
                  update_regression_priority_id = update_regression_issue.priority_id
                  users[update_regression_priority_id] = Array.new
                end
                if users[update_regression_priority_id].include?(update_regression_user_id)
                  to_update_issue_11 = PersonalPriorityIssue.find(:first, :conditions => {:user_id => update_regression_user_id, :priority_id => update_regression_priority_id, :created_on => today})

                  puts "update user #{update_regression_user_id}, priority #{priority.id}"
                  to_update_issue_11.regression_issues += 1

                  to_update_issue_11.save
                else
                  users[update_regression_priority_id] << update_regression_user_id

                  a_personal_priority_issue = PersonalPriorityIssue.new_advance                   

                  puts "create user #{update_regression_user_id} priority #{update_regression_priority_id}"

                  a_personal_priority_issue.priority_name = Enumeration.find(update_regression_priority_id).name
                  a_personal_priority_issue.user_id = update_regression_user_id
                  a_personal_priority_issue.dev_name = User.find(update_regression_user_id).name
                  a_personal_priority_issue.priority_id = update_regression_priority_id
                  a_personal_priority_issue.regression_issues = 1

                  a_personal_priority_issue.save
                end
              end
            else
              puts "related issue doesn't exist!"
            end

          end
          to_update_issue_10.found_issues += 1

          to_update_issue_10.save

        #如果还没有被统计
        else
          #标识是否被统计过
          users[priority.id] << issue_created.author_id                         

          #new personal priority issue
          a_personal_priority_issue = PersonalPriorityIssue.new_advance         

          a_personal_priority_issue.priority_name = priority.name
          a_personal_priority_issue.user_id = issue_created.author_id
          a_personal_priority_issue.dev_name = User.find(issue_created.author_id).name
          a_personal_priority_issue.priority_id = priority.id
          #发现bug数置 1
          a_personal_priority_issue.found_issues += 1
          a_personal_priority_issue.save
          puts "create user #{issue_created.assigned_to_id} priority #{priority.id}"

          category = find_category(issue_created.id)

          #如果该新建类别为regression
          if category == 2                                                      
            regression_user_id = nil
            issue_to = IssueRelation.find(:first, :conditions => {:issue_from_id => issue_created.id}).issue_to_id
            if issue_to != nil
              regression_issue = Issue.find(:first, :conditions => {:id => issue_to})
              regression_journals = Journal.find(:all, :conditions => {:journalized_id => issue_to})
              unless regression_journals.empty?
                regression_journals.each do |r|
                  regression_journal_detail = JournalDetail.find(:first, :conditions => {:prop_key => 'status_id', :value => RESOLVED, :journal_id => r.id})
                  if regression_journal_detail != nil
                    regression_user_id = r.user_id
                    break
                  end
                end
              end

              regression_priority_id = priority.id
              if regression_user_id != nil
                if regression_issue.priority_id != priority.id
                  regression_priority_id = regression_issue.priority_id
                  users[regression_priority_id] = Array.new
                end
                if users[regression_priority_id].include?(regression_user_id)
                  to_update_issue_12 = PersonalPriority.find(:first, :conditions => {:user_id => regression_user_id, :priority_id => regression_priority_id, :created_on => today})

                  puts "update user #{regression_user_id} project #{regression_priority_id}"

                  to_update_issue_12.regression_issues += 1
                  to_update_issue_12.save
                else
                  users[regression_priority_id] << regression_user_id

                  a_personal_priority_issue = PersonalPriority.new_advance               

                  a_personal_priority_issue.priority_name = Enumeration.find(regression_issue.priority_id).name
                  a_personal_priority_issue.user_id = regression_user_id
                  a_personal_priority_issue.dev_name = User.find(regression_priority_id).name
                  a_personal_priority_issue.priority_id = regression_issue.priority_id
                  #regression bug 数置 1
                  a_personal_priority_issue.regression_issues += 1                       

                   #保存至数据库
                  a_personal_priority_issue.save                                        
                end
              end
            else
              puts "related issue doesn't exist!"
            end
          end
        end
      end

      puts "update issues number #{issues.count} total"
      issues.each do |issue|
        puts "issue id #{issue.id}"
        #得到该issue今天所有的更新
        issue_all_journals = Journal.find(:all, :order => 'created_on DESC', :conditions => {:journalized_id => issue.id, :created_on => (yesterday..today)})
        puts "issue journals number #{issue_all_journals.count} total"
        unless issue_all_journals.empty?
          puts "enter journals status..."
          issue_all_journals.each do |issue_journal|
            issue_journal_details = JournalDetail.find(:all, :conditions => {:journal_id => issue_journal.id})
            issue_journal_details.each do |issue_journal_detail|
              issue_prop_key = issue_journal_detail.prop_key
              #如果是状态发生更改
              if issue_prop_key == 'status_id'
                #如果更新是撤离investigating状态
                if issue_journal_detail.old_value == INVESTIGATING
                  puts "get away from invesgating..."
                  #正是此人将状态更改的
                  user_id = issue_journal.user_id                               
                  #下面计算他调研该问题所花费的时间
                  #获取该次更新时的时间
                  update_time = issue_journal.created_on
                  update_inves_time = find_update_time(issue.id, 'status_id', '',INVESTIGATING, 3)
                  if update_inves_time != -1
                    if users[priority.id].include?(user_id)
                      to_update_issue_4 = PersonalPriorityIssue.find(:first, :conditions => {:user_id => user_id, :priority_id => priority.id, :created_on => today})

                      puts "update user #{user_id} project #{priority.id}"
                      to_update_issue_4.investigating_issues += 1
                      to_update_issue_4.save
                    else
                      users[priority.id] << user_id
                      a_personal_priority_issue = PersonalPriorityIssue.new_advance                                                #new team_issue

                      puts "create user #{user_id} priority #{priority.id}"

                      a_personal_priority_issue.priority_name = priority.name
                      a_personal_priority_issue.priority_id = priority.id
                      a_personal_priority_issue.user_id = user_id
                      a_personal_priority_issue.dev_name = User.find(user_id).name

                      a_personal_priority_issue.investigating_issues += 1

                      a_personal_priority_issue.save
                    end
                  else
                    puts "error occured! can not find invesgating status"
                  end
                #该issue的状态被更新为已解决
                elsif issue_journal_detail.value == RESOLVED                         
                  puts "enter resolved status ..."
                  user_id = issue_journal.user_id                               

                  if users[priority.id].include?(user_id)
                    to_update_issue_5 = PersonalPriorityIssue.find(:first, :conditions => {:user_id => user_id, :priority_id => priority.id, :created_on => today})

                    puts "update user #{user_id} priority #{priority.id}"
                    to_update_issue_5.resolved_issues += 1
                    to_update_issue_5.save
                  else
                    users[priority.id] << user_id
                    a_personal_priority_issue = PersonalPriorityIssue.new_advance                                   

                    puts "create user #{user_id} priority #{priority.id}"

                    a_personal_priority_issue.priority_name = priority.name
                    a_personal_priority_issue.priority_id = priority.id
                    a_personal_priority_issue.user_id = user_id
                    a_personal_priority_issue.dev_name = User.find(user_id).name

                    a_personal_priority_issue.resolved_issues += 1
                    a_personal_priority_issue.save

                  end
                #如果此更新将issue的状态更新为重新打开
                elsif issue_journal_detail.value == REOPEN                         
                  puts "enter reopen status..."
                  user_id = nil
                  #开发人员的责任 reopen
                  if issue_journal_detail.old_value == RESOLVED
                    puts "dev's responsibility for reopen issue"
                    #下面寻找是who?Resolved了这个issue
                    reopen_journals = Journal.find(:all, :conditions => {:journalized_id => issue.id})
                    unless reopen_journals.empty?
                      reopen_journals.each do |rj|
                        reopen_journal_details = JournalDetail.find(:last, :conditions => {:prop_key => 'status_id', :value => RESOLVED, :journal_id => rj.id})
                        if reopen_journal_details != nil
                          user_id = rj.user_id
                        end
                      end
                    end
                    if user_id != nil
                      if users[priority.id].include?(user_id)
                        to_update_issue_6 = PersonalPriority.find(:first, :conditions => {:user_id => user_id, :priority_id => priority.id, :created_on => today})

                        puts "update user #{user_id} priority #{priority.id}"
                        to_update_issue_6.reopened_issues += 1
                        to_update_issue_6.save
                      else
                        users[priority.id] << user_id
                        a_personal_priority_issue = PersonalPriorityIssue.new_advance                                                #new team_issue

                        puts "create user #{user_id} priority #{priority.id}"

                        a_personal_priority_issue.priority_name = priority.name
                        a_personal_priority_issue.priority_id = priority.id
                        a_personal_priority_issue.user_id = user_id
                        a_personal_priority_issue.dev_name = User.find(user_id).name

                        a_personal_priority_issue.reopened_issues += 1
                        a_personal_priority_issue.save

                      end
                    end
                  #测试人员的责任 fix_reopen
                  elsif issue_journal_detail.old_value == FIXED
                    puts "test people's responsibility for reopened issue"
                    reopen_journals = Journal.find(:all, :conditions => {:journalized_id => issue.id})
                    unless reopen_journals.empty?
                      reopen_journals.each do |rj|
                        reopen_journal_details = JournalDetail.find(:last, :conditions => {:prop_key => 'status_id', :value => FIXED, :journal_id => rj.id})
                        if reopen_journal_details != nil
                          user_id = rj.user_id
                        end
                      end
                    end
                    if user_id != nil
                      if users[priority.id].include?(user_id)
                        to_update_issue_7 = PersonalPriorityIssue.find(:first, :conditions => {:user_id => user_id, :priority_id => priority.id, :created_on => today})

                        to_update_issue_7.fix_reopen_issues += 1
                        to_update_issue_7.save
                      else
                        users[priority.id] << user_id
                    
                        a_personal_priority_issue = PersonalPriorityIssue.new_advance                                           

                        puts "create user #{user_id} priority #{priority.id}"

                        a_personal_priority_issue.priority_name = priority.name
                        a_personal_priority_issue.priority_id = priority.id
                        a_personal_priority_issue.user_id = user_id
                        a_personal_priority_issue.dev_name = User.find(user_id).name

                        a_personal_priority_issue.fix_reopen_issues += 1
                        a_personal_priority_issue.save
                      end
                    end
                  end
                #如果状态被改为测试通过
                elsif issue_journal_detail.value == FIXED
                  puts "enter fixed status..."
                  user_id = issue_journal.user_id                               

                  if users[priority.id].include?(user_id)
                    to_update_issue_8 = PersonalPriorityIssue.find(:first, :conditions => {:user_id => user_id, :priority_id => priority.id, :created_on => today})

                    puts "update user #{user_id} priority #{priority.id}"
                    to_update_issue_8.fixed_issues += 1
                    to_update_issue_8.save
                  else
                    users[priority.id] << user_id

                    a_personal_priority_issue = PersonalPriorityIssue.new_advance     

                    puts "create user #{user_id} priority #{priority.id}"

                    a_personal_priority_issue.priority_name = priority.name
                    a_personal_priority_issue.priority_id = priority.id
                    a_personal_priority_issue.user_id = user_id
                    a_personal_priority_issue.dev_name = User.find(user_id).name

                    a_personal_priority_issue.fixed_issues += 1
                    a_personal_priority_issue.save

                  end
                #如果更新后状态为closed，查看bug的类型
                elsif issue_journal_detail.value == NOTABUG
                  puts "enter closed status..."
                  #该bug关闭的原因是不是bug                              
                  puts "closed reason is not a bug"
                  user_id = issue.author_id
                  if users[priority.id].include?(user_id)
                    to_update_issue_9 = PersonalPriorityIssue.find(:first, :conditions => {:user_id => user_id, :priority_id => priority.id, :created_on => today})

                    puts "update user #{user_id} priority #{priority.id}"
                    to_update_issue_9.not_issues += 1
                    to_update_issue_9.save
                  else
                    users[priority.id] << user_id

                    a_personal_priority_issue = PersonalPriorityIssue.new_advance

                    puts "create user #{user_id} priority #{priority.id}"

                    a_personal_priority_issue.priority_name = priority.name
                    a_personal_priority_issue.priority_id = priority.id
                    a_personal_priority_issue.user_id = user_id
                    a_personal_priority_issue.dev_name = User.find(user_id).name

                    a_personal_priority_issue.not_issues += 1
                    a_personal_priority_issue.save
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  desc "generate data for personal issues"
  task :generate_personal_issues_table => :environment do

    #get date of today
    today = TODAY
    #get date of yesterday
    yesterday = YESTERDAY

    puts "today is #{today.to_s}, get the data of yesterday #{yesterday.to_s}"

    issues = Issue.find(:all, :conditions => {:updated_on => (yesterday..today)})
    issues_created = Issue.find(:all, :conditions => {:created_on => (yesterday..today)})
    
    #保存该项目下该同学是否被记录
    users = Array.new
    
    puts "created issues number #{issues_created.count} total"
    issues_created.each do |issue_created|
      #如果该人员今天被统计过
      if users.include?(issue_created.author_id)                                
        to_update_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => issue_created.author_id, :created_on => today})
        to_update_personal_issue.found_issues += 1
        to_update_personal_issue.save
        puts "update user_id #{issue_created.author_id}"

        update_category = find_category(issue_created.id)

        if update_category == 2
          #寻找到是who?Resolved的该issue
          update_regression_user_id = nil                                       
          #该类型issue新建时必须制定关联issue，即因为是哪个issue引起的
          update_issue_to = IssueRelation.find(:first, :conditions => {:issue_from_id => issue_created.id}).issue_to_id
          if update_issue_to != nil
            update_regression_issue = Issue.find(:first, :conditions => {:id => update_issue_to})
            update_regression_journals = Journal.find(:all, :conditions => {:journalized_id => update_issue_to})
            unless update_regression_journals.empty?
              update_regression_journals.each do |ur|
                update_regression_journal_detail = JournalDetail.find(:last, :conditions => {:prop_key => 'status_id', :value => RESOLVED, :journal_id => ur.id})
                if update_regression_journal_detail != nil
                  update_regression_user_id = ur.user_id
                  break
                end
              end
            end

            if update_regression_user_id != nil
              if users.include?(update_regression_user_id)
                to_update_regression_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => update_regression_user_id, :created_on => today})

                puts "update user #{update_regression_user_id}"
                to_update_regression_personal_issue.regression_issues += 1

                to_update_regression_personal_issue.save
              else
                users << update_regression_user_id

                a_personal_issue = PersonalIssue.new_advance                    

                puts "create user #{update_regression_user_id}"

                a_personal_issue.user_id = update_regression_user_id
                a_personal_issue.p_name = User.find(update_regression_user_id).name

                a_personal_issue.regression_issues = 1

                a_personal_issue.save
              end
            end
          else
            puts "related issue doesn't exist!"
          end
        end        

      #如果还没有被统计
      else
        #将该issue的作者加入users哈希表中
        users << issue_created.author_id                                        


        a_personal_issue = PersonalIssue.new_advance                          

        a_personal_issue.user_id = issue_created.author_id
        a_personal_issue.p_name = User.find(issue_created.author_id).name
        #发现bug数置 1
        a_personal_issue.found_issues += 1
        a_personal_issue.save
        puts "create user #{issue_created.assigned_to_id}"

        category = find_category(issue_created.id)

        #如果该新建类别为regression
        if category == 2                                                        
          regression_user_id = nil
          issue_to = IssueRelation.find(:first, :conditions => {:issue_from_id => issue_created.id}).issue_to_id
          if issue_to != nil
            regression_issue = Issue.find(:first, :conditions => {:id => issue_to})
            regression_journals = Journal.find(:all, :conditions => {:journalized_id => issue_to})
            unless regression_journals.empty?
              regression_journals.each do |r|
                regression_journal_detail = JournalDetail.find(:first, :conditions => {:prop_key => 'status_id', :value => RESOLVED, :journal_id => r.id})
                if regression_journal_detail != nil
                  regression_user_id = r.user_id
                  break
                end
              end
            end

            if regression_user_id != nil
              if users.include?(regression_user_id)
                to_update_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => regression_user_id, :created_on => today})

                puts "update user #{regression_user_id}"

                to_update_personal_issue.regression_issues += 1
                to_update_personal_issue.save
              else
                users << regression_user_id

                a_personal_issue = PersonalIssue.new_advance                    

                a_personal_issue.user_id = regression_user_id
                a_personal_issue.p_name = User.find(regression_user_id).name

                #regression bug 数置 1
                a_personal_issue.regression_issues += 1                         

                #保存至数据库
                a_personal_issue.save                                           
              end
            end
          else
            puts "related issue doesn't exist!"
          end
        end 
      end
    end


    puts "update issues number #{issues.count} total"
    issues.each do |issue|
      puts "issue id #{issue.id}"
      #得到该issue今天所有的更新
      issue_all_journals = Journal.find(:all, :order => 'created_on DESC', :conditions => {:journalized_id => issue.id, :created_on => (yesterday..today)})
      puts "issue journals number #{issue_all_journals.count} total"
      unless issue_all_journals.empty?
        puts "enter journals status..."
        issue_all_journals.each do |issue_journal|
          issue_journal_details = JournalDetail.find(:all, :conditions => {:journal_id => issue_journal.id})
          issue_journal_details.each do |issue_journal_detail|
            issue_prop_key = issue_journal_detail.prop_key
            if issue_prop_key == 'status_id'
              #如果更新是撤离investigating状态
              if issue_journal_detail.old_value == INVESTIGATING
                puts "get away from invesgating..."
                #正是此人将状态更改的
                user_id = issue_journal.user_id                                 
                #下面计算他调研该问题所花费的时间
                #获取该次更新时的时间
                update_time = issue_journal.created_on
                update_inves_time = find_update_time(issue.id, 'status_id', '',INVESTIGATING, 3)
                assigned_to_time = nil
                inves_time = nil
                if update_inves_time != -1
                  #计算在调研的过程中指派人有没有更改
                  judge_journals = Journal.find(:all, :order => 'created_on', :conditions => {:journalized_id => issue.id, :created_on => (update_inves_time..update_time)})
                  judge_journals.each do |judge_journal|
                    judge_journal_details = JournalDetail.find(:last, :conditions => {:prop_key => 'assigned_to_id', :value => user_id} )
                    if judge_journal_details != nil
                      puts "assiged people has ever changed!"
                      assigned_to_time = judge_journal.created_on
                      break
                    end
                  end
                  if assigned_to_time != nil
                    #调研时间以分钟为单位
                    inves_time = ((update_time.to_i - assigned_to_time.to_i)/60.0).to_i           
                  else
                    inves_time = ((update_time.to_i - update_inves_time.to_i)/60.0).to_i
                  end


                  if users.include?(user_id)
                    to_update_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => user_id, :created_on => today})

                    puts "update user #{user_id}"

                    to_update_personal_issue.investigating_issues += 1
                    to_update_personal_issue.inves_time += inves_time

                    to_update_personal_issue.save
                  else
                    users << user_id
                    a_personal_issue = PersonalIssue.new_advance

                    puts "create user #{user_id}"

                    a_personal_issue.user_id = user_id
                    a_personal_issue.p_name = User.find(user_id).name

                    a_personal_issue.investigating_issues += 1
                    a_personal_issue.inves_time += inves_time

                    a_personal_issue.save
                  end
                else
                  puts "error occured! can not find invesgating status"
                end
              #该issue的状态被更新为已解决
              elsif issue_journal_detail.value == RESOLVED
                puts "enter resolved status ..."
                #该版本无法处理Resolved后将project更改的情况
                user_id = issue_journal.user_id                                 

                if users.include?(user_id)
                  to_update_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => user_id, :created_on => today})

                  puts "update user #{user_id}"
                  to_update_personal_issue.resolved_issues += 1
                  to_update_personal_issue.save
                else
                  users << user_id
                  a_personal_issue = PersonalIssue.new_advance

                  puts "create user #{user_id}"
 
                  a_personal_issue.user_id = user_id
                  a_personal_issue.p_name = User.find(user_id).name

                  a_personal_issue.resolved_issues += 1
                  a_personal_issue.save

                end
              #如果此更新将issue的状态更新为重新打开
              elsif issue_journal_detail.value == REOPEN
                puts "enter reopen status..."
                user_id = nil
                #开发人员的责任 reopen
                if issue_journal_detail.old_value == RESOLVED
                  puts "dev's responsibility for reopen issue"
                  #下面寻找是who?Resolved了这个issue
                  reopen_journals = Journal.find(:all, :conditions => {:journalized_id => issue.id})
                  unless reopen_journals.empty?
                    reopen_journals.each do |rj|
                      reopen_journal_details = JournalDetail.find(:last, :conditions => {:prop_key => 'status_id', :value => RESOLVED, :journal_id => rj.id})
                      if reopen_journal_details != nil
                        user_id = rj.user_id
                      end
                    end
                  end
                  if user_id != nil
                    if users.include?(user_id)
                      to_update_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => user_id, :created_on => today})

                      puts "update user #{user_id}"
                      to_update_personal_issue.reopened_issues += 1
                      to_update_personal_issue.save
                    else
                      users << user_id
                      a_personal_issue = PersonalIssue.new_advance

                      a_personal_issue.user_id = user_id
                      a_personal_issue.p_name = User.find(user_id).name

                      a_personal_issue.reopened_issues += 1
                      a_personal_issue.save

                    end
                  end
                #测试人员的责任 fix_reopen
                elsif issue_journal_detail.old_value == FIXED
                  puts "test people's responsibility for reopened issue"
                  reopen_journals = Journal.find(:all, :conditions => {:journalized_id => issue.id})
                  unless reopen_journals.empty?
                    reopen_journals.each do |rj|
                      reopen_journal_details = JournalDetail.find(:last, :conditions => {:prop_key => 'status_id', :value => FIXED, :journal_id => rj.id})
                      if reopen_journal_details != nil
                        user_id = rj.user_id
                      end
                    end
                  end
                  if user_id != nil
                    if users.include?(user_id)
                      to_update_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => user_id, :created_on => today})

                      to_update_personal_issue.fix_reopen_issues += 1
                      to_update_personal_issue.save
                    else
                      users << user_id
                      a_personal_issue = PersonalIssue.new_advance

                      a_personal_issue.user_id = user_id
                      a_personal_issue.p_name = User.find(user_id).name

                      a_personal_issue.fix_reopen_issues += 1
                      a_personal_issue.save
                    end
                  end
                end
              elsif issue_journal_detail.value == FIXED
                puts "enter fixed status..."
                user_id = issue_journal.user_id                               

                if users.include?(user_id)
                  to_update_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => user_id, :created_on => today})

                  puts "update user #{user_id}"
                  to_update_personal_issue.fixed_issues += 1
                  to_update_personal_issue.save
                else
                  users << user_id
                  a_personal_issue = PersonalIssue.new_advance

                  puts "create user #{user_id}"

                  a_personal_issue.user_id = user_id
                  a_personal_issue.p_name = User.find(user_id).name

                  a_personal_issue.fixed_issues += 1
                  a_personal_issue.save

                end
              #如果更新后状态为closed，查看bug的类型
              elsif issue_journal_detail.value == CLOSED
                puts "enter closed status..."
                #该bug关闭的原因是不是bug                                 
                user_id = issue.author_id
                if users.include?(user_id)
                  to_update_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => user_id, :created_on => today})

                  puts "update user #{user_id}"
                  to_update_personal_issue.not_issues += 1
                  to_update_personal_issue.save
                else
                  users << user_id
                  a_personal_issue = PersonalIssue.new_advance

                  puts "create user #{user_id}"

                  a_personal_issue.user_id = user_id
                  a_personal_issue.p_name = User.find(user_id).name

                  a_personal_issue.not_issues += 1
                  a_personal_issue.save
                end
              end
            #如果指派人更改，并且当前状态为invesgating，计算停留在该指派人头上的时间
            elsif issue_prop_key == 'assigned_to_id'                            
              puts "enter propkey assigned_to_id changed..."
              #得到当前的issue号
              issue_id = issue.id                                               
              user_from_id = issue_journal_detail.old_value
              user_id = user_from_id.to_i

              start_assigned_time = nil
              update_assigned_time = issue_journal.created_on

              start_inves_time = nil
              finish_inves_time = nil

              journals_before_assigned = Journal.find(:all, :conditions => ["journalized_id = ? and created_on <= ?", issue_id, update_assigned_time])

              journals_before_assigned.each do |journal_before_assigned|
                journal_details_before_assigned = JournalDetail.find(:all, :conditions => {:journal_id => journal_before_assigned.id, :prop_key => 'status_id'})

                journal_details_before_assigned.each do |jd|
                  #开始调研
                  if jd.value == INVESTIGATING
                    start_inves_time = journal_before_assigned.created_on
                  end
                  #结束调研
                  if jd.old_value == INVESTIGATING
                    finish_inves_time = journal_before_assigned.created_on
                  end
                end
              end

              #如果当前处于inves状态
              if start_inves_time != nil and finish_inves_time == nil           
                journals_duration_inves = Journal.find(:all, :conditions => {:journalized_id => issue.id, :created_on => (start_inves_time..update_assigned_time)})
                journals_duration_inves.each do |journal_duration_inves|
                  journal_details_duration_inves = JournalDetail.find(:all, :conditions => {:journal_id => journal_duration_inves.id})
                  journal_details_duration_inves.each do |journal_detail_duration_inves|
                    if journal_detail_duration_inves.prop_key == 'assigned_to_id' and journal_detail_duration_inves.value == user_from_id
                      puts "find assigned changed from user"
                      start_assigned_time = journal_duration_inves.created_on
                    end
                  end
                end
              end

              if start_assigned_time != nil
                inves_time = ((update_assigned_time.to_i - start_assigned_time.to_i)/60.0).to_i
                if users.include?(user_id)
                  to_update_personal_issue = PersonalIssue.find(:first, :conditions => {:user_id => user_id, :created_on => today})

                  puts "update user #{user_id}"
                  to_update_personal_issue.inves_time += inves_time
                  to_update_personal_issue.save
                else
                  users << user_id
                  a_personal_issue = PersonalIssue.new_advance                                 

                  puts "create user #{user_id}"

                  a_personal_issue.user_id = user_id
                  a_personal_issue.dev_name = User.find(user_id).name

                  a_personal_issue.inves_time += inves_time
                  a_personal_issue.save
                end
              end
            end
          end
        end
      end
    end
  end

  #将每天要执行的任务放在一起，每天固定时间执行
  desc "daily task for building the database"
  task :daily_task do
    Rake::Task["statistics:generate_active_issues_table"].invoke
    Rake::Task["statistics:generate_team_issues_table"].invoke
    Rake::Task["statistics:generate_personal_priority_issues_table"].invoke
    Rake::Task["statistics:generate_personal_issues_table"].invoke
  end

  desc "rake environment test"
  task :test do
    puts "this is a test"
  end
end
