# require 'resque_bus/tasks'
# will give you these tasks

require "queue_bus/tasks"
require "resque/tasks"

namespace :resquebus do
  # deprecated
  task :setup => ["queuebus:setup"] do
    ResqueBus.note_deprecation "[DEPRECATION] rake resquebus:setup is deprecated. Use rake queuebus:setup instead."
  end

  task :driver => ["queuebus:driver"] do
    ResqueBus.note_deprecation "[DEPRECATION] rake resquebus:driver is deprecated. Use rake queuebus:driver instead."
  end

  task :subscribe => ["queuebus:subscribe"] do
    ResqueBus.note_deprecation "[DEPRECATION] rake resquebus:subscribe is deprecated. Use rake queuebus:subscribe instead."
  end

  task :unsubsribe => ["queuebus:unsubsribe"] do
    ResqueBus.note_deprecation "[DEPRECATION] rake resquebus:driver is deprecated. Use rake queuebus:unsubsribe instead."
  end
end

namespace :resque do
  Rake::Task[:work].enhance ['queuebus:set_redis_server']
end

namespace :queuebus do

  desc 'Sets the resque worker to use the QueueBus Redis server'
  task :set_redis_server do
    unless ENV['USE_QUEUEBUS_REDIS'].nil?
      Resque.redis = QueueBus.adapter.queuebus_redis
    end
  end

  Rake::Task[:subscribe].enhance [:use_queuebus_redis]
  Rake::Task[:unsubscribe].enhance [:use_queuebus_redis]

  desc "Setup will configure a resque task to run before resque:work"
  task setup: [:preload, :use_queuebus_redis] do
    if ENV['QUEUES'].nil?
      manager = ::QueueBus::TaskManager.new(true)
      queues = manager.queue_names
      ENV['QUEUES'] = queues.join(",")
    else
      queues = ENV['QUEUES'].split(",")
    end

    if queues.size == 1
      puts "  >>  Working Queue : #{queues.first}"
    else
      puts "  >>  Working Queues: #{queues.join(", ")}"
    end
  end

  desc "Instruct Resque to use the QueueBus redis instance"
  task :use_queuebus_redis do
    # We pass state through the environment because the actual worker runs
    # in a different process
    ENV["USE_QUEUEBUS_REDIS"] = "true"
  end

  desc "Sets the queue to work the driver  Use: `rake queuebus:driver resque:work`"
  task :driver => [:preload, :use_queuebus_redis] do
    ENV['QUEUES'] = ::QueueBus.incoming_queue
  end

  # Preload app files if this is Rails
  task :preload do
    require "resque"
    require "resque-bus"
    require "resque/failure/redis"
    require "resque/failure/multiple_with_retry_suppression"

    Resque::Failure::MultipleWithRetrySuppression.classes = [Resque::Failure::Redis]
    Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression

    Rake::Task["resque:setup"].invoke # loads the environment and such if defined
  end


  # examples to test out the system
  namespace :example do
    desc "Publishes events to example applications"
    task :publish => [ "queuebus:preload", "queuebus:setup" ] do
      which = ["one", "two", "three", "other"][rand(4)]
      QueueBus.publish("event_#{which}", { "rand" => rand(99999)})
      QueueBus.publish("event_all", { "rand" => rand(99999)})
      QueueBus.publish("none_subscribed", { "rand" => rand(99999)})
      puts "published event_#{which}, event_all, none_subscribed"
    end

    desc "Sets up an example config"
    task :register => [ "queuebus:preload"] do
      QueueBus.dispatch("example") do
        subscribe "event_one" do
          puts "event1 happened"
        end

        subscribe "event_two" do
          puts "event2 happened"
        end

        high "event_three" do
          puts "event3 happened (high)"
        end

        low "event_.*" do |attributes|
          puts "LOG ALL: #{attributes.inspect}"
        end
      end
    end

    desc "Subscribes this application to QueueBus example events"
    task :subscribe => [ :register, "queuebus:subscribe" ]

    desc "Start a QueueBus example worker"
    task :work => [ :register, "queuebus:setup", "resque:work" ]

    desc "Start a QueueBus example worker"
    task :driver => [ :register, "queuebus:driver", "resque:work" ]
  end
end
