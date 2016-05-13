module QueueBus
  module Subscriber

    # Store the QueueBus implementation of perform so we can wrap it
    @base_perform = ClassMethods.instance_method(:perform)

    module ClassMethods
      # Wrap the QueueBus implementation of perform so the calls to Resque
      # invoke the local Resque instance, not that used by QueueBus
      def perform(attributes)
        with_local_redis do
          Subscriber.instance_variable_get(:@base_perform)
            .bind(self)[attributes]
        end
      end

      private

      def with_local_redis(&block)
        prior_redis = ::Resque.redis
        ::Resque.redis = QueueBus.adapter.resque_redis
        block.call(::Resque.redis) if block
      ensure
        ::Resque.redis = prior_redis
      end
    end
  end
end
