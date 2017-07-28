require 'celluloid/current'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'timeout'

# Requester
class Requester
  include Celluloid

  # Request
  def request(url)
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
  def process(html_data)
    @st = :busy
    kw = html_data.xpath("//meta[@name='keywords']/@content").first.try(:value).try(:split, ',')
    # Write result
    CSV.open('./db/townwork-result.csv', 'ab') { |csv| csv << [url, kw] }
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

  def initialize(processor, urls)
    @processor = processor
    @requester = requester
    @raw_html = []
    @urls = urls
  end

  def free_processor
    processor.find { |actor| actor.free? }
  end

  def rock!
    every(REQUEST_INTERVAL) {
      raw = requester.async.request(urls.pop)
      raw_html << raw if raw.present?
    }

    loop do
      if raw_html.blank?
        sleep 1 # Take a rest
        next if raw_html.blank?
      end

      raw_html.delete_if do |raw|
        processor = free_processor
        processor.async.process(raw) if processor.present?
        processor.present?
      end
    end
  end
end

# get list of URLS
urls = CSV.read('./db/sitemap.csv')

# Create 10 proxy crawlers
container = Celluloid::Supervision::Container.new do
  names = (1..10).map { |name| "processor_#{name}" }
  names.each { |name| Celluloid.supervise type: Processor, as: "processor_#{name}" }
end

processors = names.map { |name| Celluloid::Actor[name] }

# Supervise those proxy crawlers
container.async.run

Celluloid.supervise type: Requester, as: :requester
requester = Celluloid::Actor[:requester]

Crawler.new(processors, requester, urls).rock!
