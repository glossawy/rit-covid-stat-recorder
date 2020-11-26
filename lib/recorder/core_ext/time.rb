class Time
  def self.parse_or_not(x)
    parse(x)
  rescue TypeError
    x
  end
end
