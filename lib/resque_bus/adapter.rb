module QueueBus
  module Adapters
    class Resque < QueueBus::Adapters::Base

      def enabled!
        # know we are using it
        require 'resque'
        require 'resque/scheduler'
        require 'resque-retry'

        QueueBus::Worker.extend(::Resque::Plugins::ExponentialBackoff)
        QueueBus::Worker.extend(::QueueBus::Adapters::Resque::RetryHandlers)
      end

      def redis=(server)
        @queuebus_redis = nil
        @queuebus_redis_url = server
      end

      def resque_redis
        @resque_redis || ::Resque.redis
      end

      # This method returns the QueueBus Redis instance
      # If it is not configured, it will default to the same instance as Resque.
      # If it is configured, it will me intialized, memoized, and returned.
      def queuebus_redis
        @queuebus_redis ||
          if @queuebus_redis_url
            # The configuration has specified a custom server just for QueueBus.
            # Resque doesn't offer a mechanism to create a Redis object without
            # assignment, though, so we invoke assignment for its side-effects.

            # Save the default Resque redis connection
            @resque_redis = ::Resque.redis
            begin
              # Get Resque to generate the connection given the server definition
              ::Resque.redis = @queuebus_redis_url
              # Store the Redis namespace that Resque created...
              @queuebus_redis = ::Resque.redis
            ensure
              # ...and restore the default.
              ::Resque.redis = @resque_redis
            end
            @queuebus_redis
          else
            ::Resque.redis
          end
      end

      def with_queuebus_redis(&block)
        default_redis = ::Resque.redis
        ::Resque.redis = queuebus_redis
        block.call(::Resque.redis)
      ensure
        ::Resque.redis = default_redis
      end

      def redis(&block)
        with_queuebus_redis do
          block.call(::Resque.redis)
        end
      end

      def enqueue(queue_name, klass, json)
        with_queuebus_redis do
          ::Resque.enqueue_to(queue_name, klass, json)
        end
      end

      def enqueue_at(epoch_seconds, queue_name, klass, json)
        with_queuebus_redis do
          ::Resque.enqueue_at_with_queue(queue_name, epoch_seconds, klass, json)
        end
      end

      def setup_heartbeat!(queue_name)
        # turn on the heartbeat
        # should be down after loading scheduler yml if you do that
        # otherwise, anytime
        name     = 'resquebus_heartbeat'
        schedule = { 'class' => '::QueueBus::Heartbeat',
                     'cron'  => '* * * * *',   # every minute
                     'queue' => queue_name,
                     'description' => 'I publish a heartbeat_minutes event every minute'
                   }
        if ::Resque::Scheduler.dynamic
          ::Resque.set_schedule(name, schedule)
        end
        ::Resque.schedule[name] = schedule
      end

      private

      module RetryHandlers
        # @failure_hooks_already_ran on https://github.com/defunkt/resque/tree/1-x-stable
        # to prevent running twice
        def queue
          @my_queue
        end

        def on_failure_aaa(exception, *args)
          # note: sorted alphabetically
          # queue needs to be set for rety to work (know what queue in Requeue.class_to_queue)
          hash = ::QueueBus::Util.decode(args[0])
          @my_queue = hash["bus_rider_queue"]
        end

        def on_failure_zzz(exception, *args)
          # note: sorted alphabetically
          @my_queue = nil
        end
      end
    end
  end
end
