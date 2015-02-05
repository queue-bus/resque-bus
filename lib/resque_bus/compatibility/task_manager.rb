module ResqueBus
  class TaskManager < ::QueueBus::TaskManager
    def initialize(logging)
      ResqueBus.note_deprecation "[DEPRECATION] ResqueBus::TaskManager is deprecated. Use QueueBus::TaskManager instead."
      super(logging)
    end
  end
end