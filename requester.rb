require 'celluloid/current'
require 'open-uri'
require 'csv'

# Requester
class Requester
  include Celluloid
  TIMEOUT = 0.1

  # Celluloid not return as normal
  def request(url)
    p "requesting...#{url}"
    result = Timeout.timeout(TIMEOUT) { Nokogiri::HTML(open(url)) }
    [url, result]
  rescue
    [url, 'TIMEOUT-ERR']
  end
end
