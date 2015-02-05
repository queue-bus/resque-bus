module ResqueBus
  # publishes on a delay
  class Publisher
    class << self
      def perform(event_type, attributes = {})
        attributes["bus_event_type"] = event_type # now using one hash only
        ResqueBus.note_deprecation "[MIGRATION] Note: new events will be using QueueBus::Publisher"
        ::QueueBus::Publisher.perform(attributes)
      end
    end

  end
end
