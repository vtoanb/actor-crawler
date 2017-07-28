require 'celluloid/current'

# concurrency example
class Rocket
  include Celluloid

  def launch
    count ||= 3
    begin
      p "#{count}..."
      count -= 1
      sleep 1
    end while count > 0
    p "launch!!!"
  end
end
