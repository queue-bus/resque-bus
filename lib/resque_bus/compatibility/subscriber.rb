module ResqueBus
  module Subscriber
    def self.included(base)
      ResqueBus.note_deprecation "[DEPRECATION] ResqueBus::Subscriber is deprecated. Use QueueBus::Subscriber instead."
      base.send(:include, ::QueueBus::Subscriber)
    end
  end
end
