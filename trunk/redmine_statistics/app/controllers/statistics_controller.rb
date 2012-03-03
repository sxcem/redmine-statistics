class StatisticsController < ApplicationController
  unloadable

  def versions_ajax
    @version = Version.find(:all, :conditions => {:project_id => params[:project_id]})
    render :layout => false
  end
  
  def index
  end
end
