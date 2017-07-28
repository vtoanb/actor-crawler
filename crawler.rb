require 'celluloid/current'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'timeout'

class Requester
  include Celluloid

  # Request
  def request(url)
    @st = :busy
    result = Timeout.timeout(3) { Nokogiri::HTML(open(url)) } rescue 'TIMEOUT_ERR'
    @st = :free
    [url, result]
  end
end

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

class TaskManager
  include Celluloid
  REQUEST_INTERVAL = 2

  attr_reader :raw_html, :actors, :urls
  
  def initialize(actors, urls)
    @actors = actors
    @raw_html = []
    @urls = urls
  end
  
  def free_actor
    actors.find { |actor| actor.free? }
  end
  
  def rock!
    every(REQUEST_INTERVAL) {
      raw = Celluloid::Actor[:requester].async.request(urls.pop)
      raw_html << raw if raw.present?
    }

    loop do
      # if there are no free actor
      if raw_html.blank?
        sleep 1  # Take a rest
        next if raw_html.blank?
      end

      raw_html.delete_if do |raw|
        actor = free_actor
        free_actor.async.process(raw) if actor.present?
        actor.present?
      end
    end
  end
end

# get list of URLS
urls = CSV.read('./db/sitemap.csv')


# Create 10 proxy crawlers
container = Celluloid::Supervision::Container.new do
  10.times { |i| supervise type: Processor, as: "processor_#{i}" }
  # Or shorter
end

manager = TaskManager.new()

Celluloid.supervise type: Requester, as: :requester

# Supervise those proxy crawlers
container.async.run
