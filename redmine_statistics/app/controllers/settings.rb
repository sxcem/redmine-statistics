#程序中用到的一些设置参数

class Settings
  #获取所有的项目
  PROJECTS = Project.find(:all)
  #获取所有的优先级
  PRIORITIES = Enumeration.find(:all, :conditions => "type = 'IssuePriority'")
  #获取所有的user
  USERS = User.find(:all, :conditions => "type='User'")
  #获取所有的tracker
  TRACKERS = Tracker.find(:all)
  #获取所有的状态
  STATUSES = IssueStatus.find(:all, :conditions => "is_closed = '0'")
  #获取所有的团队
  TEAMS = Group.find(:all)
  #测试人员
  TEST_ROLE_NAME = '测试人员'

  #调研中
  INVESTIGATING_NAME = '调研中 INVESTIGATING'

  def self.get_utc_today(time)
    utc_time = time.gmtime
    str_date = utc_time.strftime("%Y-%m-%d")
    return Date.parse(str_date)
  end

  def self.get_utc_date_from_str(str_date)
    time = Time.local(str_date)
    utc_time = time.gmtime
    date = utc_time.strftime("%Y-%m-%d")
    return date
  end

  def self.get_version_name
    version_name = Hash.new
    projects = Project.find(:all)
    projects.each do |project|
      versions = Version.find(:all, :conditions => {:project_id => project.id})
      unless versions.empty?
        version_name[project.name] = Array.new
        versions.each do |version|
          version_name[project.name] << version.name
        end
      end
    end
    return version_name
  end

  #得到第一个项目下的所有版本
  def self.get_versions
    project_id = Project.find(:first).id
    versions = Version.find(:all, :conditions => {:project_id => project_id})
    return versions
  end

  def self.get_test_user
    test_users = Hash.new
    USERS.each do |u|
      member = Member.find(:first, :conditions => {:user_id => u.id})
      unless member == nil
        if Role.find(MemberRole.find(:first, :conditions => {:member_id => member.id}).role_id).name == TEST_ROLE_NAME
          test_users[u.id.to_s] = u.name
        end
      end
    end
    return test_users
  end

  def self.get_dev_user
    dev_users = Hash.new
    USERS.each do |u|
     member = Member.find(:first, :conditions => {:user_id => u.id})
      unless member == nil
        unless Role.find(MemberRole.find(:first, :conditions => {:member_id => member.id}).role_id).name == TEST_ROLE_NAME
          dev_users[u.id.to_s] = u.name
        end
      end
    end
    return dev_users
  end  
end