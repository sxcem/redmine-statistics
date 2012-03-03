Redmine 部署备忘
1.	查看公司redmine数据库结构，将相关参数修改成与公司一致
2.	将redmine_statistics文件夹拷贝到公司redmine的vendor/plugins目录下
3.	需要安装的插件有：gchartrb, 安装命令:gem install gchartrb
4.	在redmine根目录下运行命令 rake db:migrate_plugins RAILS_EVN=production 修改数据库，创建前先备份数据库
5.	将database.rake文件拷贝到lib/tasks目录下，并测试
6.	使用命令/sbin/service crond start 启动定时服务(/sbin/service crond stop 停止)
7.	编辑文件crontab ,设置rake任务，使用命令 0 1 * * * root cd redmine目录/  && rake RAILS_ENV=production statistics:daily_task --trace
8.	重启服务器
