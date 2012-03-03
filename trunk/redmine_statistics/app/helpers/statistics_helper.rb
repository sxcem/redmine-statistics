#系统的辅助函数，将一些公共的，通用方法放在这里
module StatisticsHelper
  #获得哈希表中的最大值

  def self.get_max_value(a_hash)
    max_value = 0
    a_hash.each do |key, value|
      if value.is_a?(Array)
        for v in value do
          max_value = v.to_i if (v.to_i > max_value)
        end
      else
        max_value = value.to_i if (value.to_i > max_value)
      end
    end
    return max_value
  end

  #单位是小时
  def self.get_divided_number(value1, value2)
    value2 != 0 ? format("%.1f", ((value1.to_f/value2)/(60.0*24))).to_f : 0
  end
end
