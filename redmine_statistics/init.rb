require 'redmine'

Redmine::Plugin.register :redmine_statistics do
  name 'Redmine Statistics plugin'
  author 'houyining'
  description 'this is an management and statistics system'
  version '0.0.1'

  #显示导航栏
  #menu :application_menu, :statistics, { :controller => 'statistics', :action => 'index'}, :caption => 'Statistics'
end
