module ResqueBus
  module Deprecated
    def show_deprecations=val
      @show_deprecations = val
    end

    def show_deprecations?
      return @show_deprecations if defined?(@show_deprecations)
      return true if !ENV['QUEUES'] && !ENV['QUEUE'] # not in background, probably test
      return true if ENV['VVERBOSE'] || ENV['LOGGING'] || ENV['VERBOSE']
      false
    end
    
    def note_deprecation(message)
      @noted_deprecations ||= {}
      if @noted_deprecations[message]
        @noted_deprecations[message] += 1
      else
        warn(message) if show_deprecations?
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
