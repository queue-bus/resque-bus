# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "resque_bus/version"

Gem::Specification.new do |s|
  s.name        = "resque-bus"
  s.version     = ResqueBus::VERSION
  s.authors     = ["Brian Leonard"]
  s.email       = ["brian@bleonard.com"]
  s.homepage    = "https://github.com/queue-bus/resque-bus"
  s.summary     = %q{A simple event bus on top of Resque}
  s.description = %q{A simple event bus on top of Resque. Publish and subscribe to events as they occur through a queue.}

  s.rubyforge_project = "resque-bus"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('queue-bus', '~> 0.6')
  s.add_dependency('resque', ['>= 1.10.0', '< 2.0'])
  s.add_dependency('resque-scheduler', '>= 2.0.1')
  s.add_dependency('resque-retry')

  s.add_development_dependency("rspec")
  s.add_development_dependency("timecop")
  s.add_development_dependency("json_pure")
end
