module ResqueBus
  module Deprecated
    def note_deprecation(message)
      @noted_deprecations ||= {}
      if @noted_deprecations[message]
        @noted_deprecations[message] += 1
      else
        if ENV['QUEUES'] || ENV['QUEUE'] # in background
          if ENV['VVERBOSE'] || ENV['LOGGING'] || ENV['VERBOSE']
            warn message
          end
        else # probably in test
          warn message
        end
        @noted_deprecations[message] = 1
      end
    end

    def redis
      ResqueBus.note_deprecation "[DEPRECATION] ResqueBus direct usage is deprecated. Use `QueueBus.redis` instead. Note that it also requires block usage now."
      ::Resque.redis
    end

    def redis=val
      ResqueBus.note_deprecation "[DEPRECATION] ResqueBus can no longer set redis directly. It will use Resque's instance of redis."
    end

    def method_missing(method_name, *args, &block)
      ResqueBus.note_deprecation "[DEPRECATION] ResqueBus direct usage is deprecated. Use `QueueBus.#{method_name}` instead."
      ::QueueBus.send(method_name, *args, &block)
    end
  end
end
