module ResqueBus
  class Heartbeat
    class << self
      def perform(attributes={})
        ResqueBus.note_deprecation "[MIGRATION] Note: new events will be using QueueBus::Heartbeat"
        ::QueueBus::Heartbeat.perform(attributes)
      end
    end
  end
end
