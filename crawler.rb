require './requester.rb'
require 'timers'
require 'redis'

# Celluloid.supervise type: Requester, as: :requester
Requester.supervise as: :requester

# requester = Celluloid::Actor[:requester]
timers = Timers::Group.new
redis = Redis.new

begin
  timers.every(1) { Celluloid::Actor[:requester].async.process(redis.lpop('urls')) }
  loop { timers.wait }
rescue => e
  p "Error --> #{e}"
  p 'recover....'
  sleep 1
  retry
end
