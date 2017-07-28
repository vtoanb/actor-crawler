require 'celluloid/current'

class Romeo
  include Celluloid

  def initialize
    @time = 0
  end

  def report
    @time += 1
    p "report #{@time}: I'm fine"
  end

  def suicide
    raise 'dead!!!'
  end
end
