require 'celluloid/current'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'timeout'
require 'pry'

# Requester
class Requester
  include Celluloid

  # Request
  def request(url)
    p 'requesting...'
    result = Timeout.timeout(3) { Nokogiri::HTML(open(url)) } rescue 'TIMEOUT_ERR'
    [url, result]
  end
end

# Self heal processor
class Processor
  include Celluloid

  def initialize
    @st = :free
  end

  # Heavy processing
  def process(data)
    @st = :busy
    p 'processing...'
    binding.pry
    kw = data[1].xpath("//meta[@name='keywords']/@content").first.try(:value).try(:split, ',')
    # Write result
    CSV.open('./townwork-result.csv', 'ab') { |csv| csv << [data[0], kw] }
    @st = :free
  end

  def free?
    @st == :free
  end
end

# Crawler using processor to process data, requester to handler request
class Crawler
  include Celluloid
  REQUEST_INTERVAL = 2

  attr_reader :raw_html, :processor, :requester, :urls

  def initialize(processor, requester, urls)
    @processor = processor
    @requester = requester
    @raw_html = []
    @urls = urls
  end

  def free_processor
    processor.find(&:free?)
  end

  def rock!
    every(REQUEST_INTERVAL) {
      raw = requester.async.request(urls.pop)
      raw_html << raw
    }

    loop do
      if raw_html.empty?
        p 'sleeping...'
        sleep 1 # Take a rest
        next if raw_html.empty?
      end

      raw_html.delete_if do |raw|
        processor = free_processor
        processor.async.process(raw) unless processor.nil?
        !processor.nil?
      end
    end
  end
end

# get list of URLS
urls = CSV.read('./sitemap.csv')

names = (1..10).map { |i| "processor_#{i}" }

# Create 10 proxy crawlers
container = Celluloid::Supervision::Container.new do
  names.each { |name| Celluloid.supervise type: Processor, as: name }
end

processors = names.map { |name| Celluloid::Actor[name] }

# Supervise those proxy crawlers
container.async.run

Celluloid.supervise type: Requester, as: :requester
requester = Celluloid::Actor[:requester]

Crawler.new(processors, requester, urls).rock!
