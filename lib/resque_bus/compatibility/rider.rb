require 'resque-retry'

module ResqueBus
  class Rider
    extend Resque::Plugins::ExponentialBackoff
    
    class << self
      def perform(attributes = {})
        ResqueBus.note_deprecation "[MIGRATION] Note: new events will be using QueueBus::Rider"
        ::QueueBus::Rider.perform(attributes)
      end
      
      # @failure_hooks_already_ran on https://github.com/defunkt/resque/tree/1-x-stable
      # to prevent running twice
      def queue
        @my_queue
      end
      
      def on_failure_aaa(exception, *args)
        # note: sorted alphabetically
        # queue needs to be set for rety to work (know what queue in Requeue.class_to_queue)
        @my_queue = args[0]["bus_rider_queue"]
      end
      
      def on_failure_zzz(exception, *args)
        # note: sorted alphabetically
        @my_queue = nil
      end

    end
  end
end