module ResqueBus
  class Driver
    class << self
      def perform(attributes={})
        ResqueBus.note_deprecation "[MIGRATION] Note: new events will be using QueueBus::Driver"
        ::QueueBus::Driver.perform(attributes)
      end
    end
  end
end
