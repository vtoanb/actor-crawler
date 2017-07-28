require 'celluloid/current'
require 'nokogiri'
require 'open-uri'
require 'csv'

# Requester
class Requester
  include Celluloid
  TIMEOUT = 3

  # Celluloid not return as normal
  def process(url)
    p "requesting...#{url}"
    raw = Timeout.timeout(TIMEOUT) { Nokogiri::HTML(open(url)) }
    result = raw.xpath("//meta[@name='keywords']/@content").first.value
    CSV.open('./data/townwork-result.csv', 'ab') { |csv| csv << [url, result] }
  end
end
