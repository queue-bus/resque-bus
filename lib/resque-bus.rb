require "queue-bus"
require "resque_bus/adapter"
require "resque_bus/version"

module ResqueBus
  # TODO: all of this will be removed

  autoload :Deprecated,  'resque_bus/compatibility/deprecated'
  autoload :Subscriber,  'resque_bus/compatibility/subscriber'
  autoload :TaskManager, 'resque_bus/compatibility/task_manager'
  autoload :Driver,      'resque_bus/compatibility/driver'
  autoload :Rider,       'resque_bus/compatibility/rider'
  autoload :Publisher,   'resque_bus/compatibility/publisher'
  autoload :Heartbeat,   'resque_bus/compatibility/heartbeat'

  extend ::ResqueBus::Deprecated
end

if QueueBus.has_adapter?
  warn '[ResqueBus] Not setting adapter on queue-bus because ' \
      "#{QueueBus.adapter.class.name} is already the adapter"
else
  QueueBus.adapter = QueueBus::Adapters::Resque.new
end
