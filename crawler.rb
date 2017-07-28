# require 'celluloid/debug'
require './requester.rb'
require './processor.rb'
require './scheduler.rb'

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

Scheduler.new(processors, requester).async.rock!
