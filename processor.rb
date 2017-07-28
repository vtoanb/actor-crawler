require 'celluloid/current'
require 'nokogiri'
require 'csv'

# Self heal processor
class Processor
  include Celluloid

  def initialize
    @st = :free
  end

  # Heavy processing
  def process(data)
    @st = :busy
    p "processing...#{data[0]}"
    p data
    kw = data[1].xpath("//meta[@name='keywords']/@content").first.value
    # Write result
    CSV.open('./data/townwork-result.csv', 'ab') { |csv| csv << [data[0], kw] }
    @st = :free
  end

  def free?
    @st == :free
  end
end
