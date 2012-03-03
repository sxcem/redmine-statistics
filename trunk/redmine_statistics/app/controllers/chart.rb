require 'rubygems'
require 'google_chart'
require 'chart_color'

class Chart
  #初始化图标对象
  def initialize(title = nil, type = nil, data_source = nil, width = nil, height = nil)
    @title = title
    @width = width
    @height = height
    @size = (width != nil and height != nil) ? "#{width}x#{height}" : nil
    @type = type
    @data_source = data_source
    @is3D = false
    @y_segment = 10
    @chart_color = ChartColor.new
  end

  #定义setter和getter方法
  attr_accessor :title, :size, :type, :data_source, :is3D, :y_segment, :chart_color
  attr_reader :width, :height

  #重定义width=方法
  def width=(value)
    @width = value
    @size = "#{value}x#{@height}"
  end

  #重定义height=方法
  def height=(value)
    @height = value
    @size = "#{value}x#{@height}"
  end

  #设置图标颜色
  def set_chart_color(color)
    @chart_color.reset_priority_color if color == 'priority color'
    @chart_color.reset_type_color if color == 'type color'
  end

  #设置y轴标签
  def generate_y_labels(y_labels)
    @y_labels = y_labels
  end

  #设置x轴标签
  def generate_x_labels(x_labels)
    @x_labels = x_labels
  end

  #设置x轴范围
  def generate_x_range(x_range)
    @x_range = x_range
  end

  #设置y轴范围
  def generate_y_range(y_range)
    @y_range = y_range
  end

  #重写 to_s 方法
  def to_s
    "Chart type: #{@type}, Chart title: #{@title} Chart size: #{@size}"
  end

  #将y轴分成@y_segment段并设置y轴对应标签
  def get_y_labels(max_value)
    y_inteval = max_value / @y_segment.to_f;                                    
    @y_labels = Array.new
    y_factor = 0
    1.upto(@y_segment + 1){
      @y_labels << format("%.1f", y_factor).to_f
      y_factor += y_inteval
    }
  end

  #获取条形图中每条bar的宽度
  #其中10是组间隔，5为bar之间的间隔，60是留白
  def set_bar_width(count, enties, bar_number)
    if bar_number == 0
      @bar_width = 0
    else
      @bar_width = (@height - (10*enties) - enties*5*count - 60)/bar_number
    end
  end


  #获取时间粒度
  def self.getinteval(min_date, max_date)
    date_sub = max_date - min_date
    if date_sub >= 0 and date_sub <= 15
      return 1
    elsif date_sub >= 16 and date_sub <= 30
      return 2
    elsif date_sub >= 31 and date_sub <= 60
      return 4
    elsif date_sub >= 61 and date_sub <= 120
      return 8
    else
      return 16
    end
  end

  #生成图标的url
  def to_url
    unless @data_source.empty?
      #线性表
      if @type == 'line_chart'
        GoogleChart::LineChart.new(@size, @title, false ) do |lc|
          @data_source.each do |key, value|
            lc.data key, value, @chart_color[key]
          end
          lc.axis :x, :labels => @x_labels, :color => '000000', :font_size => 12, :alignment => :center
          lc.axis :y, :labels => @y_labels, :color => 'ff00ff', :font_size => 12, :alignment => :center
          lc.grid :y_step => 100/@y_segment.to_f, :length_segment => 1, :length_blank => 2

          return lc.to_url
        end
      #条形图
      elsif @type == 'bar_chart'
        GoogleChart::BarChart.new(@size, @title, :horizontal, false) do |bc|
          @data_source.each do |key, value |
            bc.data key, value, ChartColor.get_random_color
          end
          bc.axis :x, :range => @x_range
          bc.axis :y, :labels => @y_labels, :font_size => 10
          bc.width_spacing_options :bar_width => @bar_width , :bar_spacing => 5, :group_spacing => 10
          return bc.to_url
        end
      #饼图
      elsif @type == 'pie_chart'
        GoogleChart::PieChart.new(@size, @title, @is3D) do |pc|
          @data_source.each do |key, value|
            pc.data "#{key}(#{value})", value, @chart_color[key]
          end

          return pc.to_url
        end
      end
    else
      return "no_data_to_display.jpg"
    end
  end
end