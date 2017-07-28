require 'celluloid/current'

class Counter
  include Celluloid

  def counting
    every(1) { p Time.now.sec }
  end
end
