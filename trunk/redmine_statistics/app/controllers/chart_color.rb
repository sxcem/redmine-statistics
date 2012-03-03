#表格的颜色类，用来生成控制图表的颜色

class ChartColor
  def initialize
    @colors = Hash.new
  end

  attr_accessor :colors

  #向颜色库中添加颜色
  def add_color_hash(key, value)
    @colors[key] = value
  end

  #从颜色库中移除颜色
  def remove_color_hash(key)
    @colors.delete(key)
  end

  #根据优先级设置颜色
  def reset_priority_color
    add_color_hash('低 P3', 'b71ce2')
    add_color_hash('普通 P2', '08cef6')
    add_color_hash('高 P1', '4dfc02')
    add_color_hash('紧急 P0', 'e5ed11')
    add_color_hash('马上上线 P@', 'f48b0a')
  end

  #根据类型设置颜色
  def reset_type_color
    add_color_hash('Found Issues', 'b6cc93')
    add_color_hash('Resolved Issues', 'd1e751')
    add_color_hash('Regression Issues', 'd6b88a')
    add_color_hash('Investigated Issues', '049fa5')
    add_color_hash('Reopened Issues', '049fa5')
    add_color_hash('FixReopen Issues', '2d9efa')
    add_color_hash('Fixed Issues', '75c80e')
    add_color_hash('NotABug Issues', '9edafa')
  end

  #重定义操作符[]
  def [](index)
    @colors.empty? ? nil : @colors[index]
  end

  #得到随机颜色
  def self.get_random_color
    al_single=['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']
    random_color = ""
    1.upto(6){|i| random_color << al_single[rand(al_single.size)]}
    return random_color
  end
end