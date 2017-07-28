require 'celluloid/current'
require 'open-uri'
require 'csv'

# Requester
class Requester
  include Celluloid

  # Celluloid not return as normal
  def request(url)
    p "requesting...#{url}"
    result = Timeout.timeout(10) { Nokogiri::HTML(open(url)) } rescue 'TIMEOUT_ERR'
    [url, result]
  end
end
