require 'celluloid/current'

class Scheduler
  include Celluloid
  REQUEST_INTERVAL = 2
  PROCESS_INTERVAL = 0.5

  attr_reader :raw_html, :processor, :requester, :urls

  def initialize(processor, requester)
    # binding.pry
    @processor = processor
    @requester = requester
    @raw_html = []
    @urls = CSV.read('./data/sitemap.csv')
  end

  def free_processor
    processor.find(&:free?)
  end

  def rock!
    every(REQUEST_INTERVAL) do
      raw_html << requester.request(urls.pop.first)
    end

    every(PROCESS_INTERVAL) do
      raw_html.delete_if do |raw|
        processor = free_processor
        processor.async.process(raw) if !processor.nil? && !raw.nil?
        !processor.nil?
      end
    end
  end
end
